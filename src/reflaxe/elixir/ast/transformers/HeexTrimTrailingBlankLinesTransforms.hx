package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexTrimTrailingBlankLinesTransforms
 *
 * WHAT
 * - Collapses multiple trailing blank lines in ~H content to a single blank line for parity.
 */
class HeexTrimTrailingBlankLinesTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = trim(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function trim(s:String):String {
        var lines = s.split("\n");
        var j = lines.length - 1;
        while (j >= 0 && StringTools.trim(lines[j]) == "") j--;
        var out = [];
        for (i in 0...j+1) out.push(lines[i]);
        // Preserve exactly one trailing blank line if any existed; keep original whitespace of the last one
        if (j < lines.length - 1) {
            out.push(lines[j + 1]);
        }
        return out.join("\n");
    }
}

#end
