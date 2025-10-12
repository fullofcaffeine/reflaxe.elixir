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
 *
 * HOW
 * - Match ERemoteCall where module is EVar("SafePubSub") and replace with
 *   EVar("Phoenix.SafePubSub") preserving function and args.
 *
 * EXAMPLES
 * Before:
 *   SafePubSub.broadcast(topic, msg)
 * After:
 *   Phoenix.SafePubSub.broadcast(topic, msg)
 */
class SafePubSubAliasFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                case EVar(v) if (v == "SafePubSub"):
                    makeASTWithMeta(EVar("Phoenix.SafePubSub"), n.metadata, n.pos);
                case ERemoteCall(mod, func, args):
                    switch (mod.def) {
                        case EVar(m) if (m == "SafePubSub"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.SafePubSub")), func, args), n.metadata, n.pos);
                        default:
                            n;
                    }
                case ECall(tgt, func, args):
                    if (tgt != null) switch (tgt.def) {
                        case EVar(m) if (m == "SafePubSub"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.SafePubSub")), func, args), n.metadata, n.pos);
                        default:
                            n;
                    } else n;
                case ERaw(code):
                    if (code != null && code.indexOf("SafePubSub.") != -1) {
                        var out = code.split("SafePubSub.").join("Phoenix.SafePubSub.");
                        makeASTWithMeta(ERaw(out), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
