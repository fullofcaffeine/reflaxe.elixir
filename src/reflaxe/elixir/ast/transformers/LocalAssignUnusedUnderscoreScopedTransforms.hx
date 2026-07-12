package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
	* LocalAssignUnusedUnderscoreScopedTransforms
	*
	* WHAT
	* - Underscore assignment binders that are not referenced later in the same
	*   block, but only within safe scopes: any def/defp except `mount`.
	*
	* WHY
	* - Silences unused local warnings in controllers, LiveView handle_event
	*   bodies, and render helpers without touching mount/3 where rebinding
	*   `socket` may be intentionally propagated.
	*
	* HOW
	* - For each EDef/EDefp whose name != "mount", rewrite EBlock/EDo children so
	*   that `name = expr` becomes `_name = expr` when `name` is not referenced in
	*   any subsequent statement within the same block. Scalar function bodies are
	*   analyzed through a synthetic block and then restored to scalar value context.

	*
	* EXAMPLES
	* - `defp unused_param(_t), do: 1` must retain `1`; the analysis block is
	*   internal and must not turn the scalar return into a discarded statement.
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class LocalAssignUnusedUnderscoreScopedTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			// Gate (relaxed for WAE): when inside LiveView modules, only allow on
			// render_* helpers and handle_event/3 to avoid false positives.
			return switch (n.def) {
				case EDef(name, args, guards, body) if (name != "mount"):
					if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
						var isRender = StringTools.startsWith(name, "render_");
						var isHandleEvent = name == "handle_event" && args != null && args.length == 3;
						var isHandleInfo = name == "handle_info" && args != null && args.length == 2;
						if (!isRender && !isHandleEvent && !isHandleInfo)
							return n;
					}
					var newBody = rewriteFunctionBody(body, collectPatternVars(args));
					makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
				case EDefp(name, args, guards, body) if (name != "mount"):
					if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
						var isRender = StringTools.startsWith(name, "render_");
						var isHandleEvent = name == "handle_event" && args != null && args.length == 3;
						var isHandleInfo = name == "handle_info" && args != null && args.length == 2;
						if (!isRender && !isHandleEvent && !isHandleInfo)
							return n;
					}
					var newBody = rewriteFunctionBody(body, collectPatternVars(args));
					makeASTWithMeta(EDefp(name, args, guards, newBody), n.metadata, n.pos);
				case EMacroCall("test", macroArgs, doBlock):
					// ExUnit "test" blocks are macro do-blocks, not def bodies, but they compile as
					// regular Elixir code and are subject to --warnings-as-errors.
					var newDoBlock = rewriteWithScope(ensureBlock(doBlock), new Map<String, Bool>(), new Map<String, Bool>());
					makeASTWithMeta(EMacroCall("test", macroArgs, newDoBlock), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	/**
	 * Rewrites a function body without changing its value context.
	 *
	 * A scalar body such as `0` or `false` is a function return value. The unused-
	 * binder analysis needs block boundaries, but returning its synthetic EBlock
	 * makes the printer treat that scalar as a discardable statement. Analyze in a
	 * block, then unwrap the single statement when the input was not already a block.
	 */
	static function rewriteFunctionBody(body:ElixirAST, outerScope:Map<String, Bool>):ElixirAST {
		if (body == null || body.def == null)
			return body;

		var hasRealBlock = switch (body.def) {
			case EBlock(_) | EDo(_): true;
			default: false;
		};
		var rewritten = rewriteWithScope(ensureBlock(body), outerScope, new Map<String, Bool>());
		if (hasRealBlock || rewritten == null || rewritten.def == null)
			return rewritten;

		return switch (rewritten.def) {
			case EBlock(statements) if (statements.length == 1): statements[0];
			default: rewritten;
		};
	}

	static function ensureBlock(node:ElixirAST):ElixirAST {
		if (node == null || node.def == null)
			return node;
		return switch (node.def) {
			case EBlock(_) | EDo(_):
				node;
			default:
				makeASTWithMeta(EBlock([node]), node.metadata, node.pos);
		};
	}

	static function rewriteWithScope(node:ElixirAST, outerScope:Map<String, Bool>, usedAfter:Map<String, Bool>):ElixirAST {
		if (node == null || node.def == null)
			return node;
		var scope = outerScope != null ? outerScope : new Map<String, Bool>();
		var usedAfterScope = usedAfter != null ? usedAfter : new Map<String, Bool>();

		return switch (node.def) {
			case EBlock(stmts):
				makeASTWithMeta(EBlock(rewriteStatementsInBlock(stmts, scope, usedAfterScope)), node.metadata, node.pos);

			case EDo(stmts):
				makeASTWithMeta(EDo(rewriteStatementsInBlock(stmts, scope, usedAfterScope)), node.metadata, node.pos);

			case ECase(expr, clauses):
				var newExpr = rewriteWithScope(expr, scope, usedAfterScope);
				var newClauses = rewriteClauses(clauses, scope, usedAfterScope);
				makeASTWithMeta(ECase(newExpr, newClauses), node.metadata, node.pos);

			case EFn(clauses):
				var outClauses = [];
				for (c in clauses) {
					var fnScope = cloneScope(scope);
					for (a in c.args)
						collectPatternVarsInto(a, fnScope);
					// Anonymous functions are isolated scopes: outer uses must not prevent unused-binder cleanup inside.
					var newGuard = c.guard != null ? rewriteWithScope(c.guard, fnScope, new Map<String, Bool>()) : null;
					var newBody = rewriteWithScope(c.body, fnScope, new Map<String, Bool>());
					outClauses.push({args: c.args, guard: newGuard, body: newBody});
				}
				makeASTWithMeta(EFn(outClauses), node.metadata, node.pos);

			case ETry(tryBody, rescueClauses, catchClauses, afterBlock, elseBlock):
				var newTryBody = rewriteWithScope(tryBody, cloneScope(scope), usedAfterScope);
				var newRescue = rescueClauses == null ? [] : [
					for (r in rescueClauses)
						{
							pattern: r.pattern,
							varName: r.varName,
							body: rewriteWithScope(r.body, cloneScope(scope), usedAfterScope)
						}
				];
				var newCatch = catchClauses == null ? [] : [
					for (c in catchClauses)
						{
							kind: c.kind,
							pattern: c.pattern,
							body: rewriteWithScope(c.body, cloneScope(scope), usedAfterScope)
						}
				];
				var newAfter = afterBlock != null ? rewriteWithScope(afterBlock, cloneScope(scope), usedAfterScope) : null;
				var newElse = elseBlock != null ? rewriteWithScope(elseBlock, cloneScope(scope), usedAfterScope) : null;
				makeASTWithMeta(ETry(newTryBody, newRescue, newCatch, newAfter, newElse), node.metadata, node.pos);

			default:
				ElixirASTTransformer.transformAST(node, child -> rewriteWithScope(child, scope, usedAfterScope));
		};
	}

	static function rewriteStatementsInBlock(stmts:Array<ElixirAST>, outerScope:Map<String, Bool>, usedAfter:Map<String, Bool>):Array<ElixirAST> {
		if (stmts == null)
			return stmts;
		var usedAfterSeed = usedAfter != null ? usedAfter : new Map<String, Bool>();

		// Precompute the scope at each statement boundary so nested rewrites can decide
		// whether a binder is a new declaration or a rebinding.
		var scopeBefore:Array<Map<String, Bool>> = [];
		var forwardScope = cloneScope(outerScope);
		for (s in stmts) {
			scopeBefore.push(cloneScope(forwardScope));
			bindFromStatement(s, forwardScope);
		}

		// Track which assignments are *rebindings* (the binder name appeared earlier in the same block).
		var rebindAt:Array<Map<String, Bool>> = [];
		var declaredSoFar = cloneScope(outerScope);
		for (i in 0...stmts.length) {
			var rebindNames = new Map<String, Bool>();
			var binders = getStatementBinders(stmts[i]);
			for (b in binders) {
				if (declaredSoFar.exists(b))
					rebindNames.set(b, true);
				declaredSoFar.set(b, true);
			}
			rebindAt.push(rebindNames);
		}

		// Precompute "used later" sets for each statement, seeded with variables used after this block
		// (e.g. variables referenced after an `if` / `case` expression that binds them inside branches).
		var usedLaterByIndex:Array<Map<String, Bool>> = [];
		for (_ in 0...stmts.length)
			usedLaterByIndex.push(new Map<String, Bool>());
		var usedLater = cloneScope(usedAfterSeed);
		var idx = stmts.length - 1;
		while (idx >= 0) {
			usedLaterByIndex[idx] = cloneScope(usedLater);
			collectUsedVars(stmts[idx], usedLater);
			idx--;
		}

		var out:Array<ElixirAST> = [];
		for (i in 0...stmts.length) {
			var stmt = stmts[i];
			var nextStmt:ElixirAST = (i + 1 < stmts.length) ? stmts[i + 1] : null;
			var stmtUsedAfter = usedLaterByIndex[i];

			// First rewrite nested blocks with knowledge of outer "used later" variables, so we do not
			// erase bindings that are only referenced after a nested `if`/`case`/`try`.
			var rewrittenNested = rewriteWithScope(stmt, scopeBefore[i], stmtUsedAfter);
			out.push(rewriteStatementBinders(rewrittenNested, stmtUsedAfter, rebindAt, i, nextStmt));
		}
		return out;
	}

	static function rewriteStatementBinders(stmt:ElixirAST, usedLater:Map<String, Bool>, rebindAt:Array<Map<String, Bool>>, idx:Int,
			nextStmt:ElixirAST):ElixirAST {
		if (stmt == null || stmt.def == null)
			return stmt;
		var rewritten = stmt;
		switch (stmt.def) {
			case EMatch(PVar(b), rhs):
				if (skipAliasToCaseScrutinee(rhs, nextStmt))
					return stmt;
				if (shouldRewriteBinder(b, usedLater)) {
					if (isRebind(b, rebindAt, idx)) {
						rewritten = makeASTWithMeta(EMatch(PWildcard, rhs), stmt.metadata, stmt.pos);
					} else {
						rewritten = makeASTWithMeta(EMatch(PVar('_' + b), rhs), stmt.metadata, stmt.pos);
					}
				}
			case EMatch(pat, rhs):
				var newPat = underscorePatternBinderIfUnused(pat, usedLater);
				if (newPat != pat) {
					rewritten = makeASTWithMeta(EMatch(newPat, rhs), stmt.metadata, stmt.pos);
				}
			case EBinary(Match, {def: EVar(b2)}, rhs2):
				if (skipAliasToCaseScrutinee(rhs2, nextStmt))
					return stmt;
				if (shouldRewriteBinder(b2, usedLater)) {
					if (isRebind(b2, rebindAt, idx)) {
						rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs2), stmt.metadata, stmt.pos);
					} else {
						rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), stmt.metadata, stmt.pos);
					}
				} else {
					switch (rhs2.def) {
						case ERemoteCall({def: EVar("Map")}, "get", ra) if (ra != null && ra.length == 2):
							switch (ra[1].def) {
								case EString(key) if (usedLater.exists(key) && !usedLater.exists(b2)):
									rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs2), stmt.metadata, stmt.pos);
								default:
							}
						default:
					}
				}
			case EBinary(Match, leftExpr, rhs3):
				var binders = getExprBinders(leftExpr);
				if (binders.length > 0) {
					var anyUsed = false;
					for (b in binders)
						if (usedLater.exists(b)) {
							anyUsed = true;
							break;
						}
					if (!anyUsed) {
						rewritten = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs3), stmt.metadata, stmt.pos);
					} else {
						var newLeft = underscoreExprBindersIfUnused(leftExpr, usedLater);
						if (newLeft != leftExpr) {
							rewritten = makeASTWithMeta(EBinary(Match, newLeft, rhs3), stmt.metadata, stmt.pos);
						}
					}
				}
			default:
		}
		return rewritten;
	}

	static function getStatementBinders(stmt:ElixirAST):Array<String> {
		if (stmt == null || stmt.def == null)
			return [];
		return switch (stmt.def) {
			case EMatch(PVar(name), _): name == null ? [] : [name];
			case EMatch(pat, _): collectPatternVarNames(pat);
			case EBinary(Match, {def: EVar(name)}, _): name == null ? [] : [name];
			case EBinary(Match, left, _): getExprBinders(left);
			default: [];
		}
	}

	static function collectPatternVarNames(p:EPattern):Array<String> {
		var out:Array<String> = [];
		collectPatternVarNamesInto(p, new Map<String, Bool>(), out);
		return out;
	}

	static function collectPatternVarNamesInto(p:EPattern, seen:Map<String, Bool>, out:Array<String>):Void {
		switch (p) {
			case PVar(name):
				if (name != null && name.length > 0 && !seen.exists(name)) {
					seen.set(name, true);
					out.push(name);
				}
			case PLiteral(_):
			case PTuple(items):
				for (it in items)
					collectPatternVarNamesInto(it, seen, out);
			case PList(items):
				for (it in items)
					collectPatternVarNamesInto(it, seen, out);
			case PCons(h, t):
				collectPatternVarNamesInto(h, seen, out);
				collectPatternVarNamesInto(t, seen, out);
			case PMap(fs):
				for (f in fs)
					collectPatternVarNamesInto(f.value, seen, out);
			case PStruct(_, fs):
				for (f in fs)
					collectPatternVarNamesInto(f.value, seen, out);
			case PBinary(segs):
				for (s in segs)
					collectPatternVarNamesInto(s.pattern, seen, out);
			case PAlias(name, inner):
				if (name != null && name.length > 0 && !seen.exists(name)) {
					seen.set(name, true);
					out.push(name);
				}
				collectPatternVarNamesInto(inner, seen, out);
			case PPin(_):
			case PWildcard:
		}
	}

	static function getExprBinders(expr:ElixirAST):Array<String> {
		if (expr == null || expr.def == null)
			return [];
		var out:Array<String> = [];
		var seen:Map<String, Bool> = new Map();
		collectExprBindersInto(expr, seen, out);
		return out;
	}

	static function collectExprBindersInto(expr:ElixirAST, seen:Map<String, Bool>, out:Array<String>):Void {
		if (expr == null || expr.def == null)
			return;
		switch (expr.def) {
			case EVar(name):
				if (name != null && name.length > 0 && !seen.exists(name) && name != "_") {
					seen.set(name, true);
					out.push(name);
				}
			case ETuple(items) | EList(items):
				for (it in items)
					collectExprBindersInto(it, seen, out);
			default:
		}
	}

	static function underscoreExprBindersIfUnused(expr:ElixirAST, usedLater:Map<String, Bool>):ElixirAST {
		if (expr == null || expr.def == null)
			return expr;
		return switch (expr.def) {
			case EVar(name):
				if (name == null || name.length == 0) expr; else if (name == "_" || name.charAt(0) == '_') expr; else if (usedLater.exists(name)) expr; else
					makeAST(EVar('_'
					+ name));
			case ETuple(items):
				makeAST(ETuple([for (it in items) underscoreExprBindersIfUnused(it, usedLater)]));
			case EList(items):
				makeAST(EList([for (it in items) underscoreExprBindersIfUnused(it, usedLater)]));
			default:
				expr;
		};
	}

	static inline function isRebind(name:String, rebindAt:Array<Map<String, Bool>>, idx:Int):Bool {
		if (name == null || name.length == 0)
			return false;
		if (rebindAt == null || idx < 0 || idx >= rebindAt.length)
			return false;
		var m = rebindAt[idx];
		return m != null && m.exists(name);
	}

	static function underscorePatternBinderIfUnused(p:EPattern, usedLater:Map<String, Bool>):EPattern {
		return switch (p) {
			case PVar(name):
				if (name == null || name.length == 0)
					return p;
				if (name == "children")
					return p;
				if (name == "_" || name.charAt(0) == '_')
					return p;
				if (usedLater.exists(name))
					return p;
				PVar('_' + name);
			case PTuple(items): PTuple([for (it in items) underscorePatternBinderIfUnused(it, usedLater)]);
			case PList(items): PList([for (it in items) underscorePatternBinderIfUnused(it, usedLater)]);
			case PCons(h, t): PCons(underscorePatternBinderIfUnused(h, usedLater), underscorePatternBinderIfUnused(t, usedLater));
			case PMap(fs): PMap([
					for (f in fs)
						{key: f.key, value: underscorePatternBinderIfUnused(f.value, usedLater)}
				]);
			case PStruct(mod, fs): PStruct(mod, [
					for (f in fs)
						{key: f.key, value: underscorePatternBinderIfUnused(f.value, usedLater)}
				]);
			case PBinary(segs): PBinary([
					for (s in segs)
						{
							pattern: underscorePatternBinderIfUnused(s.pattern, usedLater),
							size: s.size,
							type: s.type,
							modifiers: s.modifiers
						}
				]);
			case PPin(_):
				// Pins are uses, not binders; never rewrite `^var` to `^_var`.
				p;
			case PAlias(nm, inner):
				var renamedInner = underscorePatternBinderIfUnused(inner, usedLater);
				if (nm != null && nm.length > 0 && nm.charAt(0) != '_' && !usedLater.exists(nm)) {
					PAlias('_' + nm, renamedInner);
				} else {
					PAlias(nm, renamedInner);
				}
			default:
				p;
		}
	}

	static inline function shouldRewriteBinder(name:String, usedLater:Map<String, Bool>):Bool {
		if (name == null || name.length == 0)
			return false;
		if (name == "children")
			return false;
		if (name.charAt(0) == '_')
			return false;
		if (usedLater.exists(name))
			return false;
		// Elixir warns on any unused local binder regardless of RHS shape. Haxe does not, so
		// we treat unused locals as non-fatal and underscore them to keep generated code WAE-clean.
		return true;
	}

	static function collectUsedVars(node:ElixirAST, out:Map<String, Bool>):Void {
		// IMPORTANT: use exact tracking here. Variant-aware collection (snake/camel/base/underscore)
		// can produce false positives from tokens inside raw strings (e.g., "User not found"),
		// preventing legitimate unused-local underscoring and causing WAE failures.
		OptimizedVarUseAnalyzer.collectReferencedVarsExactInto(node, out);
	}

	static function skipAliasToCaseScrutinee(rhs:ElixirAST, nextStmt:ElixirAST):Bool {
		if (nextStmt == null || nextStmt.def == null)
			return false;
		var rhsVar:Null<String> = switch (rhs.def) {
			case EVar(v): v;
			default: null;
		};
		if (rhsVar == null)
			return false;
		return switch (nextStmt.def) {
			case ECase(expr, _):
				switch (expr.def) {
					case EVar(v2) if (v2 == rhsVar): true;
					default: false;
				}
			default: false;
		}
	}

	static function rewriteClauses(cs:Array<ECaseClause>, outerScope:Map<String, Bool>, usedAfter:Map<String, Bool>):Array<ECaseClause> {
		var out:Array<ECaseClause> = [];
		for (c in cs) {
			var used = new Map<String, Bool>();
			var clauseScope = cloneScope(outerScope);
			collectPatternVarsInto(c.pattern, clauseScope);
			// Clause-bound variables can be referenced after the case expression; include outer uses.
			if (usedAfter != null)
				for (k in usedAfter.keys())
					used.set(k, true);
			var newBody = rewriteWithScope(c.body, clauseScope, usedAfter);
			if (newBody != null)
				collectUsedVars(newBody, used);
			var newGuard = c.guard != null ? rewriteWithScope(c.guard, clauseScope, usedAfter) : null;
			if (newGuard != null)
				collectUsedVars(newGuard, used);
			var pat = underscoreUnusedInPattern(c.pattern, used);
			out.push({pattern: pat, guard: newGuard, body: newBody});
		}
		return out;
	}

	static function underscoreUnusedInPattern(p:EPattern, used:Map<String, Bool>):EPattern {
		return switch (p) {
			case PVar(n) if (n != null && n.length > 0 && n.charAt(0) != '_' && !used.exists(n)): PVar('_' + n);
			case PTuple(items):
				PTuple([for (i in items) underscoreUnusedInPattern(i, used)]);
			case PList(items):
				PList([for (i in items) underscoreUnusedInPattern(i, used)]);
			case PCons(h, t):
				PCons(underscoreUnusedInPattern(h, used), underscoreUnusedInPattern(t, used));
			case PMap(fs):
				PMap([for (f in fs) {key: f.key, value: underscoreUnusedInPattern(f.value, used)}]);
			case PStruct(mod, fs):
				PStruct(mod, [for (f in fs) {key: f.key, value: underscoreUnusedInPattern(f.value, used)}]);
			case PBinary(segs):
				PBinary([
					for (s in segs)
						{
							pattern: underscoreUnusedInPattern(s.pattern, used),
							size: s.size,
							type: s.type,
							modifiers: s.modifiers
						}
				]);
			case PPin(_):
				// Pins are uses, not binders; never rewrite `^var` to `^_var`.
				p;
			default:
				p;
		}
	}

	static function cloneScope(m:Map<String, Bool>):Map<String, Bool> {
		var out = new Map<String, Bool>();
		if (m != null)
			for (k in m.keys())
				out.set(k, true);
		return out;
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
				// pinned vars do not bind
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
			case PBinary(segs):
				for (s in segs)
					collectPatternVarsInto(s.pattern, out);
			default:
		}
	}
}
#end
