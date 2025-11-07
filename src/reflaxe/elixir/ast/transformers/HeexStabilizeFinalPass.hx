package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexStabilizeFinalPass
 *
 * WHAT
 * - A conservative, iteration-bounded normalizer for ~H content at the very end of the pipeline.
 * - Applies safe, idempotent string transforms in a loop until no change or MAX_ITERS is reached.
 *
 * WHY
 * - Prevents rare re-entry loops between late ~H passes (e.g., nested ~H flatten + control-tag rewrite)
 *   from causing excessively long transforms. Guarantees termination while preserving shape.
 *
 * HOW
 * - For ESigil("H", content): up to MAX_ITERS times, apply the following in sequence:
 *     1) HeexRewriteHxxBlockTransforms.rewrite(content)
 *     2) HeexNestedSigilFlattenFinalTransforms.flattenNestedHeex(content)
 *     3) HeexControlTagTransforms.rewriteControlTags(content)
 *   Stop early if content is unchanged in an iteration.
 */
class HeexStabilizeFinalPass {
  static inline var MAX_ITERS = 5;

  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function (n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ESigil(type, content, modifiers) if (type == "H"):
          var cur = content;
          var iter = 0;
          while (iter++ < MAX_ITERS) {
            var before = cur;
            // Conservative: only rerun control-tag rewrite (string-level, public API)
            cur = reflaxe.elixir.ast.TemplateHelpers.rewriteControlTags(cur);
            if (cur == before) break;
          }
          if (cur != content) makeASTWithMeta(ESigil(type, cur, modifiers), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }
}

#end
