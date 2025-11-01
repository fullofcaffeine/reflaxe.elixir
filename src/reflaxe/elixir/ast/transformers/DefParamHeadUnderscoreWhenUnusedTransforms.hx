package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * DefParamHeadUnderscoreWhenUnusedTransforms
 *
 * WHAT
 * - Renames `params` → `_params` in def/defp heads for `mount/3` and
 *   `handle_event/3` when the function body does not reference `params`.
 *
 * WHY
 * - After aligning to idiomatic `params` binders, some callbacks don't use
 *   the argument. Phoenix warns about unused variables; using `_params`
 *   silences the warning without changing behavior.
 *
 * HOW
 * - For def/defp named `mount` or `handle_event` with arity 3, check the
 *   second arg (`handle_event`) or first arg (`mount`) and rename when:
 *     - It is exactly `PVar("params")`, and
 *     - `VariableUsageCollector.usedInFunctionScope(body, "params")` is false.
 */
class DefParamHeadUnderscoreWhenUnusedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (args != null && args.length == 3):
                    if (name == "handle_event") {
                        switch (args[1]) {
                            case PVar("params") if (!VariableUsageCollector.usedInFunctionScope(body, "params") && !containsVar(body, "_params")):
                                var na = args.copy(); na[1] = PVar("_params");
                                makeASTWithMeta(EDef(name, na, guards, body), n.metadata, n.pos);
                            default: n;
                        }
                    } else if (name == "mount") {
                        switch (args[0]) {
                            case PVar("params") if (!VariableUsageCollector.usedInFunctionScope(body, "params") && !containsVar(body, "_params")):
                                var na2 = args.copy(); na2[0] = PVar("_params");
                                makeASTWithMeta(EDef(name, na2, guards, body), n.metadata, n.pos);
                            default: n;
                        }
                    } else n;
                case EDefp(name2, args2, guards2, body2) if (args2 != null && args2.length == 3):
                    if (name2 == "handle_event") {
                        switch (args2[1]) {
                            case PVar("params") if (!VariableUsageCollector.usedInFunctionScope(body2, "params") && !containsVar(body2, "_params")):
                                var nb = args2.copy(); nb[1] = PVar("_params");
                                makeASTWithMeta(EDefp(name2, nb, guards2, body2), n.metadata, n.pos);
                            default: n;
                        }
                    } else if (name2 == "mount") {
                        switch (args2[0]) {
                            case PVar("params") if (!VariableUsageCollector.usedInFunctionScope(body2, "params") && !containsVar(body2, "_params")):
                                var nb2 = args2.copy(); nb2[0] = PVar("_params");
                                makeASTWithMeta(EDefp(name2, nb2, guards2, body2), n.metadata, n.pos);
                            default: n;
                        }
                    } else n;
                default: n;
            }
        });
    }

    static function containsVar(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST) {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(e2, cs): walk(e2); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(cls, doBlock, elseBlock): for (wc in cls) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(tg, _, as): if (tg != null) walk(tg); if (as != null) for (a in as) walk(a);
                case ERemoteCall(tg2, _, as2): walk(tg2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                default:
            }
        }
        walk(body); return found;
    }
}

#end
