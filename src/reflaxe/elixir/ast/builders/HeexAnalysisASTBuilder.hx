package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;

/**
 * HeexAnalysisASTBuilder
 *
 * WHAT
 * - Builds a typed HEEx fragment AST (EFragment/EAttribute + expression nodes) for analysis only.
 * - Normalizes HXX authoring constructs (control tags + interpolations) to valid HEEx before parsing.
 *
 * WHY
 * - Raw HXX content can include control tags like `<if { ... }>` / `<for { ... }>` and `${...}`
 *   interpolations that are not valid HTML. Parsing those directly causes the typed HEEx builder
 *   (`HeexFragmentBuilder`) to fail, disabling downstream static analysis.
 * - Linter passes rely on `metadata.heexAST` for robust attribute/expression validation.
 *
 * HOW
 * - Rewrite the ~H content using `HeexControlTagTransforms.rewrite` (for-blocks + interpolations + if/else).
 * - Parse the rewritten string with `HeexFragmentBuilder.build`.
 * - If parsing fails, return `[]` to keep compilation deterministic (analysis-only metadata).
 *
 * EXAMPLES
 * HXX:
 *   HXX.hxx('<div><if {@show}><button disabled={@disabled}>OK</button></if></div>')
 * Analysis input:
 *   <div><%= if @show do %><button disabled={@disabled}>OK</button><% end %></div>
 */
class HeexAnalysisASTBuilder {
    public static function build(content: String): Array<ElixirAST> {
        if (content == null || content.length == 0) return [];
        try {
            var normalized = reflaxe.elixir.ast.transformers.HeexControlTagTransforms.rewrite(content);
            return HeexFragmentBuilder.build(normalized);
        } catch (_) {
            return [];
        }
    }
}

#end
