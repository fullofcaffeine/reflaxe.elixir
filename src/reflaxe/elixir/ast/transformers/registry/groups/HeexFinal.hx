package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexFinal
 *
 * WHAT
 * - Ultra-late HEEx cleanups (final quote/blank-line trims) preserving snapshot style.
 */
class HeexFinal {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];
    passes.push({
      name: "HeexCollapseOverEscapedQuotes_Final",
      description: "Final normalization of escaped quotes inside ~H inline strings",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexCollapseOverEscapedQuotesTransforms.transformPass
    });
    passes.push({
      name: "HeexTrimTrailingBlankLines_Final",
      description: "Final collapse of trailing blank lines in ~H content to match snapshot style",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexTrimTrailingBlankLinesTransforms.transformPass
    });
    return passes;
  }
}
#end

