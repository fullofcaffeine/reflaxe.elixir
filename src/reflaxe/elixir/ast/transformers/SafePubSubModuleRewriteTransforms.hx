package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SafePubSubModuleRewriteTransforms
 *
 * WHAT
 * - Rewrite bare SafePubSub.* calls to Phoenix.SafePubSub.* inside any module.
 *
 * WHY
 * - When alias injection is not present or fails ordering-wise, ensure fully-qualified
 *   Phoenix.SafePubSub is used to avoid undefined module warnings under WAE.
 *
 * HOW
 * - Replace ERemoteCall(mod=EVar("SafePubSub"), func, args) with ERemoteCall(EVar("Phoenix.SafePubSub"), func, args).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SafePubSubModuleRewriteTransforms {
    public static function rewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args):
                    switch (mod.def) {
                        case EVar(m) if (m == 'SafePubSub'):
                            #if debug_safe_pubsub_rewrite
                            #end
                            var newMod = makeASTWithMeta(EVar('Phoenix.SafePubSub'), mod.metadata, mod.pos);
                            makeASTWithMeta(ERemoteCall(newMod, func, args), n.metadata, n.pos);
                        default: n;
                    }
                case ECall(tgt, func2, args2):
                    if (tgt != null) switch (tgt.def) {
                        case EVar(m2) if (m2 == 'SafePubSub'):
                            #if debug_safe_pubsub_rewrite
                            #end
                            var newTgt = makeASTWithMeta(EVar('Phoenix.SafePubSub'), tgt.metadata, tgt.pos);
                            makeASTWithMeta(ECall(newTgt, func2, args2), n.metadata, n.pos);
                        default: n;
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
