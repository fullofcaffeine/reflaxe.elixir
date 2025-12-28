package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountParamsPromoteTransforms
 *
 * WHAT
 * - Promotes the first parameter of Phoenix LiveView mount/3 from `_params`
 *   to `params` when referenced in the body, and rewrites occurrences.
 *
 * WHY
 * - Avoid warnings: "the underscored variable `_params` is used after being set".
 *
 * HOW
 * - Detect EDef name "mount" with 3 args, first arg PVar `_...` used in body.
 * - Rename to base and rewrite body occurrences from underscored → base.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class MountParamsPromoteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length == 3):
                    switch (args[0]) {
                        case PVar(pn) if (pn != null && pn.length > 1 && pn.charAt(0) == '_'):
                            if (containsVar(body, pn)) {
                                var base = pn.substr(1);
                                var nArgs = args.copy();
                                nArgs[0] = PVar(base);
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

    static inline function containsVar(body: ElixirAST, name: String): Bool {
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

    static inline function rewriteVar(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                default: n;
            }
        });
    }
}

#end

