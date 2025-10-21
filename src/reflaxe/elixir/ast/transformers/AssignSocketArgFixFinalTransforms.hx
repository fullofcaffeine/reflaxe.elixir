package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignSocketArgFixFinalTransforms
 *
 * WHAT
 * - Absolute-final targeted fix: ensures calls to Phoenix.Component.assign/2
 *   use `socket` as the first argument when `_socket` slipped through.
 *
 * WHY
 * - After late mount promotion, some code paths may still reference `_socket`
 *   in assign/2, producing an "underscored variable used" warning. This pass
 *   normalizes the first argument to `socket` when appropriate.
 *
 * HOW
 * - For any ERemoteCall(_, "assign", args) where args[0] is EVar("_socket"),
 *   rewrite args[0] to EVar("socket").
 */
class AssignSocketArgFixFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, fn, args) if (fn == "assign" && args != null && args.length >= 1):
                    var a0 = args[0];
                    switch (a0.def) {
                        case EVar(v) if (v == "_socket"):
                            var newArgs = args.copy();
                            newArgs[0] = makeAST(EVar("socket"));
                            makeASTWithMeta(ERemoteCall(mod, fn, newArgs), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end

