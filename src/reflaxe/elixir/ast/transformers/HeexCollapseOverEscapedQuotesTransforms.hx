package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexCollapseOverEscapedQuotesTransforms
 *
 * WHAT
 * - Collapses over-escaped quotes inside ~H content: \\\" → \" (double backslash to single)
 *
 * WHY
 * - Some earlier string-building steps may double-escape quotes within inline-if HTML strings.
 *   HEEx expects a single-escaped quote in Elixir string literals.
 *
 * HOW
 * - For ESigil("H", content): perform textual replacement of \\\" with \".
 */
class HeexCollapseOverEscapedQuotesTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = collapse(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function collapse(s:String):String {
        // Replace occurrences of \\" (two backslashes before a quote) with \"
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            if (i + 2 < s.length && s.charAt(i) == '\\' && s.charAt(i + 1) == '\\' && s.charAt(i + 2) == '"') {
                // \\" -> \"
                parts.push('\\"');
                i += 3;
                continue;
            }
            if (i + 1 < s.length && s.charAt(i) == '\\' && s.charAt(i + 1) == '"') {
                // \" -> "
                parts.push('"');
                i += 2;
                continue;
            }
            parts.push(s.charAt(i));
            i++;
        }
        return parts.join("");
    }
}

#end
