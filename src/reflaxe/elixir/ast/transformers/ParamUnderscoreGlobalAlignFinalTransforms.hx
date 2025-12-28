package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ParamUnderscoreGlobalAlignFinalTransforms
 *
 * WHAT
 * - Absolute-final safety pass: in defs named `handle_event` (arity 3) or
 *   `mount` (arity 3), replace body occurrences of `_params` with `params`,
 *   regardless of the declared argument name. This complements the targeted
 *   promotions and ensures no dangling `_params` references remain.
 *
 * WHY
 * - Some late rewrites can reintroduce `_params` or disturb earlier ordering.
 *   This pass guarantees consistency without app-specific coupling.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ParamUnderscoreGlobalAlignFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if ((name == "handle_event" || name == "mount") && args != null && args.length == 3):
                    var nb = rewrite(body, "_params", "params");
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if ((name2 == "handle_event" || name2 == "mount") && args2 != null && args2.length == 3):
                    var nb2 = rewrite(body2, "_params", "params");
                    makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewrite(body: ElixirAST, from:String, to:String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end

