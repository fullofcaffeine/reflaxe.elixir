package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalUnderscoreGenericPromotionFinalTransforms
 *
 * WHAT
 * - Replay of LocalUnderscoreGenericPromotionTransforms at absolute-final stage
 *   to catch shapes introduced by late passes.
 */
class LocalUnderscoreGenericPromotionFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return LocalUnderscoreGenericPromotionTransforms.pass(ast);
  }
}
#end

