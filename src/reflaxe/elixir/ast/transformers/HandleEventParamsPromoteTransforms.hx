package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsPromoteTransforms
 *
 * WHAT
 * - Promotes the second parameter of Phoenix LiveView handle_event/3 from
 *   an underscored name (e.g., `_params`) to `params` when it is referenced
 *   in the function body, and rewrites body usages accordingly.
 *
 * WHY
 * - Elixir warns when underscored parameters are used. Generated wrappers
 *   frequently name the second arg `_params` for hygiene, but downstream
 *   wrappers read from it (e.g., Map.get(_params, "id")). This shape is
 *   framework-derived and generic; not app-coupled.
 *
 * HOW
 * - Detect EDef named `handle_event` with exactly 3 args.
 * - If the second arg is `PVar` with a leading underscore and the body
 *   references that name, rename arg to the base (without underscore) and
 *   rewrite body occurrences to the base.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventParamsPromoteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
                    var second = args[1];
                    switch (second) {
                        case PVar(pn) if (pn != null && pn.length > 1 && pn.charAt(0) == '_'):
                            var base = pn.substr(1);
                            // Check if body references underscored name
                            var used = containsVar(body, pn);
                            if (used) {
                                var nArgs = args.copy();
                                nArgs[1] = PVar(base);
                                var nBody = rewriteVar(body, pn, base);
                                makeASTWithMeta(EDef(name, nArgs, guards, nBody), n.metadata, n.pos);
                            } else n;
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function containsVar(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, cs): walk(expr); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                default:
            }
        }
        walk(body);
        return found;
    }

    static function rewriteVar(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                default: n;
            }
        });
    }
}

#end

