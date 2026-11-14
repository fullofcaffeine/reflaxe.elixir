package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
	* CaseTupleBinderUnshadowTransforms
	*
	* WHAT
	* - For case expressions that scrutinize a function argument (e.g., `case socket do`),
	*   if a tuple clause binds the same name as the argument in the second position
	*   (e.g., `{:tag, socket}`), rename that binder to `value` and, when the clause
	*   body references exactly one undefined lower-case local, prefix-bind that
	*   local to `value`.
	*
	* WHY
	* - Prevents shadowing of function args in tuple patterns and repairs bodies
	*   that expect a meaningful name (e.g., `todo`). Shape-based; no app coupling.

	*
	* HOW
	* - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.
	* - When the guard or body reads the binder under the shared name, rename those reads
	*   too. A nested enum pattern, such as `Err(Stale(wanted, _))`, builds
	*   `case g do {:err, g} -> case g do {:stale, wanted, _} -> ...`; the inner `g` is the
	*   binder. The result is `case g do {:err, value} -> case value do ...`.
	*   If the clause binds the name again, or already uses `value`, leave it unchanged.
	*   Regression fixture: `regression/nested_enum_pattern_outer_value`.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseTupleBinderUnshadowTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EDef(name, args, guards, body):
					var params = argNameSet(args);
					var nb = rewriteBody(body, params);
					makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
				case EDefp(name2, args2, guards2, body2):
					var params2 = argNameSet(args2);
					var nb2 = rewriteBody(body2, params2);
					makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function argNameSet(args:Array<EPattern>):Map<String, Bool> {
		var s = new Map<String, Bool>();
		for (a in args)
			switch (a) {
				case PVar(n) if (n != null && n.length > 0):
					s.set(n, true);
				default:
			}
		return s;
	}

	static function rewriteBody(body:ElixirAST, params:Map<String, Bool>):ElixirAST {
		return ElixirASTTransformer.transformNode(body, function(x:ElixirAST):ElixirAST {
			return switch (x.def) {
				case ECase(expr, clauses):
					// Trigger when scrutinizing a simple variable; avoid atoms/tuples/maps
					var scrName:Null<String> = switch (expr.def) {
						case EVar(v): v;
						default: null;
					};
					if (scrName == null)
						return x;
					var out:Array<ECaseClause> = [];
					for (c in clauses)
						out.push(repairClause(c, scrName));
					makeASTWithMeta(ECase(expr, out), x.metadata, x.pos);
				default:
					x;
			}
		});
	}

	static function repairClause(c:ECaseClause, scrutinee:String):ECaseClause {
		// If pattern matches {:atom, PVar(scrutinee)}, rename binder to value
		var binderName:Null<String> = null;
		var pat2 = switch (c.pattern) {
			case PTuple(es) if (es.length == 2):
				switch (es[1]) {
					case PVar(n) if (n == scrutinee):
						binderName = "value";
						PTuple([es[0], PVar(binderName)]);
					default: c.pattern;
				}
			default: c.pattern;
		};
		if (binderName == null)
			return c;
		// The binder had the name of the scrutinee, so it shadowed it in this clause.
		// Reads of that name in the guard or body are reads of the binder and must
		// follow the rename. Example: `case g do {:err, g} -> case g do {:stale, ...`.
		var readsBinder = usesName(c.body, scrutinee) || (c.guard != null && usesName(c.guard, scrutinee));
		if (readsBinder) {
			// Rename only when it is certainly right: every read of the name is free
			// (nothing in the clause binds it again) and `value` is not in use.
			var freeReads = VarUseAnalyzer.freeVarUseCounts(c.body).get(scrutinee);
			var allReadsFree = freeReads != null && freeReads == countReads(c.body, scrutinee);
			var valueInUse = usesName(c.body, binderName)
				|| (c.guard != null && usesName(c.guard, binderName))
				|| collectDeclared(c.pattern, c.body).exists(binderName);
			if (!allReadsFree || valueInUse)
				return c;
			return {
				pattern: pat2,
				guard: c.guard != null ? renameReads(c.guard, scrutinee, binderName) : null,
				body: renameReads(c.body, scrutinee, binderName)
			};
		}
		// If body references exactly one undefined lower-case local, prefix bind it to value
		var declared = collectDeclared(pat2, c.body);
		// Nested case patterns and closure parameters own their local names.
		// Only reads free in this body can need the existing outer repair.
		var used = VarUseAnalyzer.freeVarNames(c.body);
		var undef:Array<String> = [];
		for (u in used.keys())
			if (!declared.exists(u) && allowLocal(u))
				undef.push(u);
		if (undef.length == 1) {
			var chosen = undef[0];
			var prefix = makeAST(EBinary(Match, makeAST(EVar(chosen)), makeAST(EVar(binderName))));
			var body2 = switch (c.body.def) {
				case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), c.body.metadata, c.body.pos);
				case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), c.body.metadata, c.body.pos);
				default: makeASTWithMeta(EBlock([prefix, c.body]), c.body.metadata, c.body.pos);
			};
			return {pattern: pat2, guard: c.guard, body: body2};
		}
		return {pattern: pat2, guard: c.guard, body: c.body};
	}

	/** Counts the reads of `name` in `node`, at any depth. A pattern that binds the name is not a read. */
	static function countReads(node:ElixirAST, name:String):Int {
		var reads = 0;
		reflaxe.elixir.ast.ASTUtils.walk(node, function(n:ElixirAST):Void {
			switch (n.def) {
				case EVar(candidate) if (candidate == name):
					reads++;
				default:
			}
		});
		return reads;
	}

	/** True when `node` reads `name` at any depth. */
	static function usesName(node:ElixirAST, name:String):Bool {
		return countReads(node, name) > 0;
	}

	/** Returns `node` with every read of `from` changed to a read of `to`. */
	static function renameReads(node:ElixirAST, from:String, to:String):ElixirAST {
		return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EVar(candidate) if (candidate == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
				default: n;
			}
		});
	}

	static function allowLocal(name:String):Bool {
		if (name == null || name.length == 0)
			return false;
		if (name == "socket" || name == "params" || name == "_params" || name == "event")
			return false;
		var c = name.charAt(0);
		return c.toLowerCase() == c;
	}

	static function collectDeclared(p:EPattern, body:ElixirAST):Map<String, Bool> {
		var m = new Map<String, Bool>();
		function pat(pt:EPattern):Void {
			switch (pt) {
				case PVar(n):
					m.set(n, true);
				case PTuple(es) | PList(es):
					for (e in es)
						pat(e);
				case PCons(h, t):
					pat(h);
					pat(t);
				case PMap(kvs):
					for (kv in kvs)
						pat(kv.value);
				case PStruct(_, fs):
					for (f in fs)
						pat(f.value);
				case PPin(inner):
					pat(inner);
				default:
			}
		}
		pat(p);
		// Declarations in body (LHS of assignments)
		reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST) {
			switch (n.def) {
				case EMatch(pt, _):
					pat(pt);
				case EBinary(Match, {def: EVar(lhs)}, _):
					m.set(lhs, true);
				default:
			}
		});
		return m;
	}
}
#end
