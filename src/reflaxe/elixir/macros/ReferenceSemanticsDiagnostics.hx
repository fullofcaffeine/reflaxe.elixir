package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import sys.FileSystem;

private typedef ArrayAliasCandidate = {
	final root:TVar;
	final alias:TVar;
	var mutated:Null<TVar>;
	var mutationPos:Null<Position>;
}

private typedef CanonicalArrayPush = {
	final receiver:TVar;
	final position:Position;
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
 * - Scans fields, constructors, and class initialization one lexical block at a time.
 * - Abandons a candidate on nested sequencing, escape, overwrite, another mutation,
 *   or any reference shape that is not proven.
 * - Treats source below the compilation root as owned. Exact compiler and framework
 *   classpaths are excluded through marker files, not user directory names.
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
		var compilerOwnedRoots = findCompilerOwnedRoots(projectRoot);
		Context.onAfterTyping(types -> diagnose(types, projectRoot, compilerOwnedRoots));
	}

	static function diagnose(types:Array<ModuleType>, projectRoot:String, compilerOwnedRoots:Array<String>):Void {
		for (moduleType in types) {
			switch (moduleType) {
				case TClassDecl(classRef):
					var classType = classRef.get();
					if (!isProjectSource(classType.pos, projectRoot, compilerOwnedRoots)) {
						continue;
					}

					var scannedFields = new Map<String, Bool>();
					for (field in classType.fields.get().concat(classType.statics.get())) {
						scanFieldExpression(field, scannedFields);
					}

					if (classType.constructor != null) {
						scanFieldExpression(classType.constructor.get(), scannedFields);
					}

					if (classType.init != null) {
						scanExpression(classType.init);
					}

				case _:
			}
		}
	}

	/** Scans each class expression once, including constructors that Haxe stores separately. */
	static function scanFieldExpression(field:ClassField, scannedFields:Map<String, Bool>):Void {
		var position = Context.getPosInfos(field.pos);
		var key = '${position.file}:${position.min}:${position.max}:${field.name}';
		if (scannedFields.exists(key)) {
			return;
		}
		scannedFields.set(key, true);

		var expression = field.expr();
		if (expression != null) {
			scanExpression(expression);
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

			if (isAmbiguousControlFlowBoundary(direct) || containsNestedSequencingBoundary(direct)) {
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
					if (sameVariable(receiver, peer) && candidateUseIsOnly(expression, candidate, peer)) {
						reportStaleAlias(candidate, peer);
					}
				}
			}

			if (isTerminalControlFlow(direct)) {
				freshArrays = [];
				candidates = [];
				continue;
			}

			var push = canonicalArrayPush(direct);
			if (push != null) {
				var kept:Array<ArrayAliasCandidate> = [];
				for (candidate in candidates) {
					if (!candidateContains(candidate, push.receiver)) {
						if (!expressionReferencesCandidate(expression, candidate)) {
							kept.push(candidate);
						}
						continue;
					}

					if (candidate.mutated == null && candidateUseIsOnly(expression, candidate, push.receiver)) {
						candidate.mutated = push.receiver;
						candidate.mutationPos = push.position;
						kept.push(candidate);
					}
				}
				candidates = kept;
				invalidateReferencedFreshArrays(expression, freshArrays);
				continue;
			}

			switch (direct.expr) {
				case TVar(variable, initializer) if (initializer != null && isFreshArrayLiteral(initializer)):
					invalidateReferencedFreshArrays(expression, freshArrays);
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
					invalidateReferencedFreshArrays(expression, freshArrays);
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

		Context.error('Reflaxe.Elixir cannot preserve this shared Array mutation. The current lowering would update only `${mutated.name}`, '
			+ 'so `${peer.name}.length` would read the old Array. Avoid the shared alias. For example, compute a new Array with `concat(...)` '
			+ 'and use that binding. This diagnostic covers one narrow pattern. Other shared aliases remain unsupported.',
			position);
	}

	static function invalidateReferencedFreshArrays(expression:TypedExpr, freshArrays:Array<TVar>):Void {
		var kept = freshArrays.filter(variable -> !expressionReferencesVariable(expression, variable));
		freshArrays.resize(0);
		for (variable in kept) {
			freshArrays.push(variable);
		}
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

	/** Requires one candidate-local occurrence, which must be the recognized receiver. */
	static function candidateUseIsOnly(expression:TypedExpr, candidate:ArrayAliasCandidate, expected:TVar):Bool {
		var rootUses = countVariableReferences(expression, candidate.root);
		var aliasUses = countVariableReferences(expression, candidate.alias);
		return sameVariable(expected, candidate.root) ? rootUses == 1 && aliasUses == 0 : aliasUses == 1 && rootUses == 0;
	}

	static function countVariableReferences(expression:TypedExpr, expected:TVar):Int {
		var count = 0;
		function visit(current:TypedExpr):Void {
			switch (current.expr) {
				case TLocal(actual) if (sameVariable(actual, expected)):
					count++;
				case _:
			}
			TypedExprTools.iter(current, visit);
		}
		visit(expression);
		return count;
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

	static function canonicalArrayPush(expression:TypedExpr):Null<CanonicalArrayPush> {
		return switch (expression.expr) {
			case TCall({expr: TField(receiverExpression, FInstance(classRef, _, fieldRef))}, [_])
				if (isCanonicalArrayClass(classRef.get()) && fieldRef.get().name == "push"):
				var receiver = directLocal(receiverExpression);
				receiver == null ? null : {receiver: receiver, position: expression.pos};
			case TVar(_, initializer) if (initializer != null):
				canonicalArrayPush(unwrap(initializer));
			case TBinop(OpAssign, _, value):
				canonicalArrayPush(unwrap(value));
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

	/** Finds sequencing boundaries below a statement so parent alias facts never enter them. */
	static function containsNestedSequencingBoundary(expression:TypedExpr):Bool {
		var found = false;
		function visit(current:TypedExpr):Void {
			if (found) {
				return;
			}

			var direct = unwrap(current);
			if (isAmbiguousControlFlowBoundary(direct) || isShortCircuitExpression(direct)) {
				found = true;
				return;
			}
			TypedExprTools.iter(direct, visit);
		}
		TypedExprTools.iter(expression, visit);
		return found;
	}

	static function isShortCircuitExpression(expression:TypedExpr):Bool {
		return switch (expression.expr) {
			case TBinop(OpBoolAnd | OpBoolOr, _, _): true;
			case _: false;
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

	static function isProjectSource(position:Position, projectRoot:String, compilerOwnedRoots:Array<String>):Bool {
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

		for (compilerOwnedRoot in compilerOwnedRoots) {
			if (StringTools.startsWith(file, compilerOwnedRoot)) {
				return false;
			}
		}
		return true;
	}

	/** Identifies compiler and framework classpaths by owned marker files, not user directory names. */
	static function findCompilerOwnedRoots(projectRoot:String):Array<String> {
		var roots:Array<String> = [];
		for (classPath in Context.getClassPath()) {
			var absolute = normalizePath(Path.isAbsolute(classPath) ? classPath : Path.join([projectRoot, classPath]));
			if (hasCompilerOwnedMarker(absolute)) {
				roots.push(ensureTrailingSlash(absolute));
			}
		}
		return roots;
	}

	static function hasCompilerOwnedMarker(classPath:String):Bool {
		return FileSystem.exists(Path.join([classPath, "reflaxe", "elixir", "CompilerInit.hx"]))
			|| FileSystem.exists(Path.join([classPath, "elixir", "otp", "TypeSafeChildSpec.hx"]))
			|| FileSystem.exists(Path.join([classPath, "reflaxe", "ReflectCompiler.hx"]))
			|| FileSystem.exists(Path.join([classPath, "phoenix", "channels", "WireCodecs.hx"]));
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
