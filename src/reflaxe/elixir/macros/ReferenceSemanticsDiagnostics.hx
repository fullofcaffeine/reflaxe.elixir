package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

private typedef ArrayAliasCandidate = {
	final root:TVar;
	final alias:TVar;
	var mutated:Null<TVar>;
	var mutationPos:Null<Position>;
}

/**
 * Rejects narrowly proven Haxe reference-semantics mismatches before code generation.
 *
 * WHAT
 * - Detects one straight-line Array pattern: a fresh literal, one direct local alias,
 *   `push` through either binding, and a later `length` read through the other binding.
 *
 * WHY
 * - Haxe requires both bindings to observe the append. The current Elixir lowering
 *   rebinds one immutable list, so the peer binding would read a stale length.
 * - A compile-time error is safer than generated code with silently different behavior.
 *
 * HOW
 * - Reads canonical typed identities during `Context.onAfterTyping`.
 * - Scans one lexical block at a time and abandons a candidate on control flow,
 *   escape, overwrite, another mutation, or any reference shape that is not proven.
 * - Scans project-local source only. Third-party dependency code remains outside
 *   this initial compatibility boundary and is not thereby known to be safe.
 *
 * This checker does not rewrite code, infer an authoring profile, or claim general
 * alias analysis. Managed reference support remains the complete future solution.
 */
class ReferenceSemanticsDiagnostics {
	public static function init():Void {
		if (!isElixirBuild()) {
			return;
		}

		var projectRoot = normalizePath(Sys.getCwd());
		Context.onAfterTyping(types -> diagnose(types, projectRoot));
	}

	static function diagnose(types:Array<ModuleType>, projectRoot:String):Void {
		for (moduleType in types) {
			switch (moduleType) {
				case TClassDecl(classRef):
					var classType = classRef.get();
					if (!isProjectSource(classType.pos, projectRoot)) {
						continue;
					}

					for (field in classType.fields.get().concat(classType.statics.get())) {
						var expression = field.expr();
						if (expression != null) {
							scanExpression(expression);
						}
					}

				case _:
			}
		}
	}

	/** Scans each typed block independently so candidate state never crosses a control-flow boundary. */
	static function scanExpression(expression:TypedExpr):Void {
		switch (expression.expr) {
			case TBlock(expressions):
				scanStraightLineBlock(expressions);
			case _:
		}

		TypedExprTools.iter(expression, scanExpression);
	}

	/**
	 * Tracks only direct local facts whose order is explicit in one block.
	 * Unknown uses remove the related candidate instead of guessing about effects.
	 */
	static function scanStraightLineBlock(expressions:Array<TypedExpr>):Void {
		var freshArrays:Array<TVar> = [];
		var candidates:Array<ArrayAliasCandidate> = [];

		for (expression in expressions) {
			var direct = unwrap(expression);

			if (isAmbiguousControlFlowBoundary(direct)) {
				freshArrays = [];
				candidates = [];
				continue;
			}

			for (receiver in findCanonicalArrayLengthReceivers(expression)) {
				for (candidate in candidates) {
					if (candidate.mutated == null || candidate.mutationPos == null) {
						continue;
					}

					var peer = sameVariable(candidate.mutated, candidate.root) ? candidate.alias : candidate.root;
					if (sameVariable(receiver, peer)) {
						reportStaleAlias(candidate, peer);
					}
				}
			}

			if (isTerminalControlFlow(direct)) {
				freshArrays = [];
				candidates = [];
				continue;
			}

			var pushedReceiver = canonicalArrayPushReceiver(direct);
			if (pushedReceiver != null) {
				var kept:Array<ArrayAliasCandidate> = [];
				for (candidate in candidates) {
					if (!candidateContains(candidate, pushedReceiver)) {
						if (!expressionReferencesCandidate(expression, candidate)) {
							kept.push(candidate);
						}
						continue;
					}

					if (candidate.mutated == null) {
						candidate.mutated = pushedReceiver;
						candidate.mutationPos = direct.pos;
						kept.push(candidate);
					}
				}
				candidates = kept;
				continue;
			}

			switch (direct.expr) {
				case TVar(variable, initializer) if (initializer != null && isFreshArrayLiteral(initializer)):
					invalidateReferencedCandidates(expression, candidates);
					freshArrays.push(variable);
					continue;

				case TVar(alias, initializer) if (initializer != null):
					var root = directLocal(initializer);
					if (root != null && containsVariable(freshArrays, root)) {
						candidates.push({
							root: root,
							alias: alias,
							mutated: null,
							mutationPos: null
						});
						freshArrays = freshArrays.filter(variable -> !sameVariable(variable, root));
						continue;
					}

					invalidateReferencedCandidates(expression, candidates);

				case _:
					invalidateReferencedCandidates(expression, candidates);
			}
		}
	}

	static function reportStaleAlias(candidate:ArrayAliasCandidate, peer:TVar):Void {
		var mutated = candidate.mutated;
		var position = candidate.mutationPos;
		if (mutated == null || position == null) {
			return;
		}

		Context.error('Reflaxe.Elixir cannot preserve this shared Array mutation. `${mutated.name}.push(...)` becomes a new immutable value, '
			+ 'but `${peer.name}.length` would read the old Array. Use an explicit returned value, or keep shared state in LiveView assigns, '
			+ 'GenServer state, or ETS. This check covers one narrow pattern. Other shared aliases remain unsupported.',
			position);
	}

	static function invalidateReferencedCandidates(expression:TypedExpr, candidates:Array<ArrayAliasCandidate>):Void {
		var kept = candidates.filter(candidate -> !expressionReferencesCandidate(expression, candidate));
		candidates.resize(0);
		for (candidate in kept) {
			candidates.push(candidate);
		}
	}

	static function expressionReferencesCandidate(expression:TypedExpr, candidate:ArrayAliasCandidate):Bool {
		return expressionReferencesVariable(expression, candidate.root) || expressionReferencesVariable(expression, candidate.alias);
	}

	static function expressionReferencesVariable(expression:TypedExpr, expected:TVar):Bool {
		var found = false;
		function visit(current:TypedExpr):Void {
			if (found) {
				return;
			}

			switch (current.expr) {
				case TLocal(actual) if (sameVariable(actual, expected)):
					found = true;
				case _:
					TypedExprTools.iter(current, visit);
			}
		}
		visit(expression);
		return found;
	}

	static function findCanonicalArrayLengthReceivers(expression:TypedExpr):Array<TVar> {
		var receivers:Array<TVar> = [];
		function visit(current:TypedExpr):Void {
			var direct = unwrap(current);
			switch (direct.expr) {
				case TField(receiverExpression, FInstance(classRef, _, fieldRef)) if (isCanonicalArrayClass(classRef.get())
					&& fieldRef.get().name == "length"):
					var receiver = directLocal(receiverExpression);
					if (receiver != null) {
						receivers.push(receiver);
					}
				case _:
			}
			TypedExprTools.iter(direct, visit);
		}
		visit(expression);
		return receivers;
	}

	static function canonicalArrayPushReceiver(expression:TypedExpr):Null<TVar> {
		return switch (expression.expr) {
			case TCall({expr: TField(receiverExpression, FInstance(classRef, _, fieldRef))}, [_])
				if (isCanonicalArrayClass(classRef.get()) && fieldRef.get().name == "push"):
				directLocal(receiverExpression);
			case _:
				null;
		}
	}

	static function directLocal(expression:TypedExpr):Null<TVar> {
		return switch (unwrap(expression).expr) {
			case TLocal(variable): variable;
			case _: null;
		}
	}

	static function isFreshArrayLiteral(expression:TypedExpr):Bool {
		return switch (unwrap(expression).expr) {
			case TArrayDecl(_): true;
			case _: false;
		}
	}

	static function isAmbiguousControlFlowBoundary(expression:TypedExpr):Bool {
		return switch (expression.expr) {
			case TIf(_, _, _) | TSwitch(_, _, _) | TWhile(_, _, _) | TFor(_, _, _) | TTry(_, _) | TFunction(_) | TBlock(_) | TBreak | TContinue:
				true;
			case _:
				false;
		}
	}

	static function isTerminalControlFlow(expression:TypedExpr):Bool {
		return switch (expression.expr) {
			case TReturn(_) | TThrow(_): true;
			case _: false;
		}
	}

	static function unwrap(expression:TypedExpr):TypedExpr {
		return switch (expression.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): unwrap(inner);
			case _: expression;
		}
	}

	static function candidateContains(candidate:ArrayAliasCandidate, variable:TVar):Bool {
		return sameVariable(candidate.root, variable) || sameVariable(candidate.alias, variable);
	}

	static function containsVariable(variables:Array<TVar>, expected:TVar):Bool {
		for (variable in variables) {
			if (sameVariable(variable, expected)) {
				return true;
			}
		}
		return false;
	}

	static inline function sameVariable(left:TVar, right:TVar):Bool {
		return left.id == right.id;
	}

	static function isCanonicalArrayClass(classType:ClassType):Bool {
		return classType.pack.length == 0 && classType.name == "Array";
	}

	static function isProjectSource(position:Position, projectRoot:String):Bool {
		var root = ensureTrailingSlash(projectRoot);
		var file = normalizePath(Context.getPosInfos(position).file);
		if (file == null || file == "") {
			return false;
		}

		if (!Path.isAbsolute(file)) {
			file = normalizePath(Path.join([root, file]));
		}

		if (!StringTools.startsWith(file, root)) {
			return false;
		}

		var compilerSource = ensureTrailingSlash(Path.join([root, "src/reflaxe"]));
		var targetStd = ensureTrailingSlash(Path.join([root, "std"]));
		return !StringTools.startsWith(file, compilerSource) && !StringTools.startsWith(file, targetStd);
	}

	static function ensureTrailingSlash(path:String):String {
		var normalized = normalizePath(path);
		return StringTools.endsWith(normalized, "/") ? normalized : normalized + "/";
	}

	static function normalizePath(path:String):String {
		return Path.normalize(path).split("\\").join("/");
	}

	static function isElixirBuild():Bool {
		var targetName = Context.definedValue("target.name");
		return targetName == "elixir" || Context.defined("elixir_output");
	}
}
#end
