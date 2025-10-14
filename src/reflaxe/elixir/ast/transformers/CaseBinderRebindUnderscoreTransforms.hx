package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderRebindUnderscoreTransforms
 *
 * WHAT
 * - In case clauses, if a pattern binder is immediately rebound in the body (binder = ...)
 *   before any usage of the original bound value, underscore the pattern binder to silence
 *   unused-variable warnings.
 *
 * WHY
 * - Patterns like `{:ok, v}` followed by `v = broadcast(...)` rebind `v`, leaving the original
 *   pattern binding unused. Elixir warns unless the pattern binder is underscored.
 *
 * HOW
 * - For each ECase clause with body as EBlock([...]), for each PVar binder name `b`:
 *   - Find first index of a top-level assignment `b = ...`
 *   - Find first index of a top-level expression that uses `b` in expression position
 *   - If rebindIndex >= 0 and (useIndex == -1 or rebindIndex < useIndex), rewrite PVar(b) to PVar("_"+b)
 *
 * EXAMPLES
 * Haxe:
 *   switch doUpdate() {
 *     case Ok(v):
 *       v = compute(v); // immediate rebind, no usage of original pattern value
 *       trace(v)
 *   }
 * Elixir (before):
 *   case do_update() do
 *     {:ok, v} -> v = compute(v); IO.inspect(v)
 *   end
 * Elixir (after):
 *   case do_update() do
 *     {:ok, _v} -> v = compute(v); IO.inspect(v)
 *   end
 */
class CaseBinderRebindUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    #if debug_hygiene
                    Sys.println('[CaseBinderRebindUnderscore] inspecting case...');
                    #end
                    var newClauses = [];
                    for (cl in clauses) {
                        var binders = collectPatternBinders(cl.pattern);
                        #if debug_hygiene
                        Sys.println('[CaseBinderRebindUnderscore] binders=' + binders.join(','));
                        #end
                        var bodyStmts:Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                        var toUnderscore:Array<String> = [];
                        for (b in binders) {
                            var rebindIdx = firstRebindIndex(bodyStmts, b);
                            var useIdx = firstUseIndex(bodyStmts, b);
                            #if debug_hygiene
                            Sys.println('[CaseBinderRebindUnderscore] binder=' + b + ' rebindIdx=' + rebindIdx + ' useIdx=' + useIdx);
                            #end
                            if (rebindIdx >= 0 && (useIdx == -1 || rebindIdx < useIdx)) {
                                toUnderscore.push(b);
                            }
                        }
                        #if debug_hygiene
                        if (toUnderscore.length > 0) Sys.println('[CaseBinderRebindUnderscore] underscore binders=' + toUnderscore.join(','));
                        #end
                        var newPat = (toUnderscore.length > 0) ? underscoreBinders(cl.pattern, toUnderscore) : cl.pattern;
                        newClauses.push({ pattern: newPat, guard: cl.guard, body: cl.body });
                    }
                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectPatternBinders(p: EPattern): Array<String> {
        var out:Array<String> = [];
        function walk(px:EPattern) {
            switch (px) {
                case PVar(n): out.push(n);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h,t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                default:
            }
        }
        walk(p);
        return out;
    }

    static function underscoreBinders(p: EPattern, names:Array<String>): EPattern {
        return switch (p) {
            case PVar(n):
                if (names.indexOf(n) != -1 && n.charAt(0) != "_") PVar("_" + n) else p;
            case PTuple(es): PTuple([for (e in es) underscoreBinders(e, names)]);
            case PList(es): PList([for (e in es) underscoreBinders(e, names)]);
            case PCons(h,t): PCons(underscoreBinders(h, names), underscoreBinders(t, names));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreBinders(kv.value, names) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreBinders(f.value, names) }]);
            case PPin(inner): PPin(underscoreBinders(inner, names));
            default: p;
        }
    }

    static function firstRebindIndex(stmts:Array<ElixirAST>, name:String):Int {
        for (i in 0...stmts.length) switch (stmts[i].def) {
            case EBinary(Match, left, _):
                switch (left.def) { case EVar(nm) if (nm == name): return i; default: }
            case EMatch(pat, _):
                switch (pat) { case PVar(nm2) if (nm2 == name): return i; default: }
            default:
        }
        return -1;
    }

    static function firstUseIndex(stmts:Array<ElixirAST>, name:String):Int {
        for (i in 0...stmts.length) if (stmtUsesVar(stmts[i], name)) return i;
        return -1;
    }

    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        function walk(x:ElixirAST, inPattern:Bool):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (!inPattern && v == name): found = true;
                case EBinary(Match, _, rhs): walk(rhs, false);
                case EMatch(_, rhs2): walk(rhs2, false);
                case EBlock(ss): for (s in ss) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt, false); for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2): walk(tgt2, false); for (a2 in args2) walk(a2, false);
                case ECase(expr, cs): walk(expr, false); for (c in cs) walk(c.body, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end
