package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.PhoenixContext;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
	* SuccessBinderPrefixMostUsedUndefinedTransforms
	*
	* WHAT
	* - For case clauses shaped as `{:ok, binder}`, if the body references one or more
	*   undefined simple variables, prefix-bind the most frequently used one to `binder`:
	*     var = binder; <body>
	*
	* WHY
	* - Complements rename-based alignment when renaming would shadow an existing outer name.
	*   Prefix-binding preserves outer references and satisfies genuinely missing locals.
	*
	* HOW
	* - For each ECase clause with `{:ok, PVar(binder)}`:
	*   - Use `VarUseAnalyzer` to count references that remain free after lexical scope
	*   - Choose the most frequent eligible local name
	*   - Prefix `name = binder` and keep the original body unchanged

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class SuccessBinderPrefixMostUsedUndefinedTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EModule(name, attrs, body) if (isPhoenixModule(name, node.metadata)):
					makeASTWithMeta(EModule(name, attrs, body.map(stmt -> transformWithScope(stmt, new Map()))), node.metadata, node.pos);
				case EDefmodule(name, doBlock) if (isPhoenixModule(name, node.metadata)):
					makeASTWithMeta(EDefmodule(name, transformWithScope(doBlock, new Map())), node.metadata, node.pos);
				default:
					node;
			}
		});
	}

	static function isPhoenixModule(name:Null<String>, metadata:Null<ElixirMetadata>):Bool {
		if (metadata != null) {
			if (metadata.phoenixContext != null && metadata.phoenixContext != PhoenixContext.None)
				return true;
			if (metadata.isPhoenixWeb == true)
				return true;
			if (metadata.isLiveView == true)
				return true;
			if (metadata.isController == true)
				return true;
			if (metadata.isRouter == true)
				return true;
			if (metadata.isEndpoint == true)
				return true;
			if (metadata.isPresence == true)
				return true;
		}

		// Fallback: common Phoenix namespace convention (e.g., MyAppWeb.*).
		return name != null && name.indexOf("Web.") != -1;
	}

	/**
	 * Scope-aware traversal.
	 *
	 * WHY
	 * - Case clause bodies can reference variables bound in the surrounding scope.
	 * - Prefix-binding an outer variable to the ok-binder corrupts semantics.
	 *
	 * HOW
	 * - Track sequential bindings in EBlock/EDo (function args + prior assignments).
	 * - Only prefix-bind names that are not declared *and* not already bound in the outer scope.
	 */
	static function transformWithScope(node:ElixirAST, inScope:Map<String, Bool>):ElixirAST {
		if (node == null || node.def == null)
			return node;

		return switch (node.def) {
			case EDef(name, args, guards, body):
				var scope = collectPatternVars(args);
				makeASTWithMeta(EDef(name, args, guards != null ? transformWithScope(guards, scope) : null, transformWithScope(body, scope)), node.metadata,
					node.pos);

			case EDefp(name, args, guards, body):
				var scope = collectPatternVars(args);
				makeASTWithMeta(EDefp(name, args, guards != null ? transformWithScope(guards, scope) : null, transformWithScope(body, scope)), node.metadata,
					node.pos);

			case EFn(clauses):
				makeASTWithMeta(EFn(clauses.map(cl -> {
					var clauseScope = cloneScope(inScope);
					for (a in cl.args)
						collectPatternVarsInto(a, clauseScope);
					{
						args: cl.args,
						guard: cl.guard != null ? transformWithScope(cl.guard, clauseScope) : null,
						body: transformWithScope(cl.body, clauseScope)
					};
				})), node.metadata, node.pos);

			case EBlock(expressions):
				var localScope = cloneScope(inScope);
				var out:Array<ElixirAST> = [];
				for (e in expressions) {
					var next = transformWithScope(e, localScope);
					out.push(next);
					bindFromStatement(next, localScope);
				}
				makeASTWithMeta(EBlock(out), node.metadata, node.pos);

			case EDo(expressions2):
				var localScope = cloneScope(inScope);
				var out:Array<ElixirAST> = [];
				for (e2 in expressions2) {
					var next = transformWithScope(e2, localScope);
					out.push(next);
					bindFromStatement(next, localScope);
				}
				makeASTWithMeta(EDo(out), node.metadata, node.pos);

			case ECase(target, clauses):
				var outClauses = [];
				for (cl in clauses) {
					var clauseScope = cloneScope(inScope);
					collectPatternVarsInto(cl.pattern, clauseScope);

					var newGuard = cl.guard != null ? transformWithScope(cl.guard, clauseScope) : null;
					var newBody = transformWithScope(cl.body, clauseScope);

					outClauses.push(processClause({pattern: cl.pattern, guard: newGuard, body: newBody}, inScope));
				}
				makeASTWithMeta(ECase(transformWithScope(target, inScope), outClauses), node.metadata, node.pos);

			default:
				ElixirASTTransformer.transformAST(node, child -> transformWithScope(child, inScope));
		};
	}

	static function processClause(cl:ECaseClause, outerScope:Map<String, Bool>):ECaseClause {
		var binder = extractOkBinder(cl.pattern);
		if (binder == null)
			return cl;

		var available = cloneScope(outerScope);
		collectPatternVarsInto(cl.pattern, available);
		var freq = VarUseAnalyzer.freeVarUseCounts(cl.body, available);
		var best:Null<String> = null;
		var bestCount = 0;
		for (k in freq.keys()) {
			if (allow(k)) {
				var c = freq.get(k);
				if (c > bestCount) {
					bestCount = c;
					best = k;
				}
			}
		}
		if (best == null)
			return cl;

		var prefix = makeAST(EBinary(Match, makeAST(EVar(best)), makeAST(EVar(binder))));
		var newBody = switch (cl.body.def) {
			case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), cl.body.metadata, cl.body.pos);
			case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), cl.body.metadata, cl.body.pos);
			default: makeASTWithMeta(EBlock([prefix, cl.body]), cl.body.metadata, cl.body.pos);
		};
		return {pattern: cl.pattern, guard: cl.guard, body: newBody};
	}

	static function bindFromStatement(stmt:ElixirAST, scope:Map<String, Bool>):Void {
		if (stmt == null || stmt.def == null)
			return;
		switch (stmt.def) {
			case EMatch(pat, _):
				collectPatternVarsInto(pat, scope);
			case EBinary(Match, left, _):
				collectLhsVars(left, scope);
			default:
		}
	}

	static function collectLhsVars(lhs:ElixirAST, out:Map<String, Bool>):Void {
		if (lhs == null || lhs.def == null)
			return;
		switch (lhs.def) {
			case EVar(nm) if (nm != null && nm.length > 0):
				out.set(nm, true);
			case EPin(_):
				// pinned vars do not bind
			case ETuple(items) | EList(items):
				for (i in items)
					collectLhsVars(i, out);
			case EKeywordList(pairs):
				for (p in pairs)
					collectLhsVars(p.value, out);
			case EMap(pairs2):
				for (p in pairs2)
					collectLhsVars(p.value, out);
			case EBinary(Match, l, r):
				collectLhsVars(l, out);
				collectLhsVars(r, out);
			default:
		}
	}

	static function collectPatternVars(args:Array<EPattern>):Map<String, Bool> {
		var out = new Map<String, Bool>();
		if (args == null)
			return out;
		for (p in args)
			collectPatternVarsInto(p, out);
		return out;
	}

	static function collectPatternVarsInto(p:EPattern, out:Map<String, Bool>):Void {
		if (p == null)
			return;
		switch (p) {
			case PVar(n) if (n != null && n.length > 0):
				out.set(n, true);
			case PAlias(nm, inner):
				if (nm != null && nm.length > 0)
					out.set(nm, true);
				collectPatternVarsInto(inner, out);
			case PPin(_):
				// pinned vars do not bind; outer scope must already contain them
			case PTuple(es) | PList(es):
				for (e in es)
					collectPatternVarsInto(e, out);
			case PCons(h, t):
				collectPatternVarsInto(h, out);
				collectPatternVarsInto(t, out);
			case PMap(kvs):
				for (kv in kvs)
					collectPatternVarsInto(kv.value, out);
			case PStruct(_, fs):
				for (f in fs)
					collectPatternVarsInto(f.value, out);
			default:
		}
	}

	static function cloneScope(m:Map<String, Bool>):Map<String, Bool> {
		var out = new Map<String, Bool>();
		if (m != null)
			for (k in m.keys())
				out.set(k, true);
		return out;
	}

	static function extractOkBinder(p:EPattern):Null<String> {
		return switch (p) {
			case PTuple(es) if (es.length == 2):
				switch (es[0]) {
					case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"): switch (es[1]) {
							case PVar(n): n;
							default: null;
						}
					default: null;
				}
			default: null;
		}
	}

	static inline function allow(name:String):Bool {
		if (name == null || name.length == 0)
			return false;
		var c = name.charAt(0);
		return c.toLowerCase() == c && c != '_';
	}
}
#end
