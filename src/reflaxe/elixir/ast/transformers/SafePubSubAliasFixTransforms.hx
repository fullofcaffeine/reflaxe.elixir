package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SafePubSubAliasFixTransforms
 *
 * WHAT
 * - Normalize bare SafePubSub remote calls to Phoenix.SafePubSub to avoid
 *   undefined module warnings in generated Elixir code.
 *
 * WHY
 * - BinderTransforms maps most module contexts, but as a safety net, this pass
 *   ensures any remaining ERemoteCall with module "SafePubSub" is fully qualified.
 */
class SafePubSubAliasFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args):
                    switch (mod.def) {
                        case EVar(m) if (m == "SafePubSub"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.SafePubSub")), func, args), n.metadata, n.pos);
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

