package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexStripDanglingQuoteLinesTransforms
 *
 * WHAT
 * - Removes lines that are solely a quote character (\" or ') inside ~H content.
 *
 * WHY
 * - Intermediate inlining/capture steps may introduce isolated quote lines around ~H content
 *   when converting ERaw(~H) to ESigil("H",...). These lines are not meaningful HEEx content
 *   and harm snapshot parity.
 *
 * HOW
 * - For ESigil("H", content), drop lines where `String.trim(line)` is exactly '"' or '\''. Preserve
 *   all other whitespace and formatting.
 */
class HeexStripDanglingQuoteLinesTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = strip(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function strip(s:String):String {
        var lines = s.split("\n");
        var out = [];
        for (ln in lines) {
            var t = StringTools.replace(ln, "\r", "");
            t = StringTools.trim(t);
            if (t == '"' || t == "'") continue;
            out.push(ln);
        }
        return out.join("\n");
    }
}

#end
