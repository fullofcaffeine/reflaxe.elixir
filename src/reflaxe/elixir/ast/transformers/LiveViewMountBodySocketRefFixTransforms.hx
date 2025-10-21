package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveViewMountBodySocketRefFixTransforms
 *
 * WHAT
 * - As an absolute-final safety net, rewrites body references to `_socket`
 *   to `socket` when inside `def mount/3` after parameter promotion.
 *
 * WHY
 * - Earlier underscore/rename passes may not re-run after late promotion of the
 *   `socket` parameter, leaving stray `_socket` references in the function body
 *   and triggering "underscored variable _socket is used after being set" warnings.
 *
 * HOW
 * - Matches EDef/EDefp named "mount" with arity >= 3 and where the third param
 *   is `PVar("socket")`. Traverses the body, replacing any EVar("_socket") with
 *   EVar("socket"). This pass is idempotent and does nothing if `_socket` is
 *   not present.
 */
class LiveViewMountBodySocketRefFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body) if (name == "mount" && hasThirdSocketParam(params)):
                    var nb = rewriteSocketRefs(body);
                    makeASTWithMeta(EDef(name, params, guards, nb), n.metadata, n.pos);
                case EDefp(name2, params2, guards2, body2) if (name2 == "mount" && hasThirdSocketParam(params2)):
                    var nb2 = rewriteSocketRefs(body2);
                    makeASTWithMeta(EDefp(name2, params2, guards2, nb2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function hasThirdSocketParam(params: Array<EPattern>): Bool {
        if (params == null || params.length < 3) return false;
        return switch (params[2]) { case PVar(p) if (p == "socket"): true; default: false; };
    }

    static function rewriteSocketRefs(body: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == "_socket"): makeASTWithMeta(EVar("socket"), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end

