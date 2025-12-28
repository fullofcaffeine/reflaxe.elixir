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

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class LocalUnderscoreGenericPromotionFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return LocalUnderscoreGenericPromotionTransforms.pass(ast);
  }
}
#end

