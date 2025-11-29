package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexInlineIfQuoteNormalizeTransforms
 *
 * WHAT
 * - Normalizes over-escaped quotes inside inline-if string branches within ~H content.
 *   Example: <%= if cond, do: "<div id=\\\"form\\\">" %> → <%= if cond, do: "<div id=\"form\">" %>
 *
 * WHY
 * - During earlier string handling, quotes may get double-escaped. Snapshots expect single-escaped quotes
 *   in Elixir string literals inside inline-if branches.
 */
class HeexInlineIfQuoteNormalizeTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = normalize(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function normalize(s:String):String {
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var open = s.indexOf("<%=", i);
            if (open == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, open - i));
            var close = s.indexOf("%>", open + 3);
            if (close == -1) { parts.push(s.substr(open)); break; }
            var inner = s.substr(open + 3, close - (open + 3));
            var trimmed = StringTools.trim(inner);
            if (StringTools.startsWith(trimmed, "if ") && trimmed.indexOf(", do:") != -1) {
                // Find quoted segments and collapse over-escaped quotes (\\\") -> (\") inside them only
                var rebuilt = rebuildInlineIf(trimmed);
                parts.push("<%= " + rebuilt + " %>");
            } else {
                parts.push(s.substr(open, (close + 2) - open));
            }
            i = close + 2;
        }
        return parts.join("");
    }

    static function rebuildInlineIf(inner:String):String {
        var rebuilt:Array<String> = [];
        var i = 0;
        var inD = false; var inS = false;
        while (i < inner.length) {
            var ch = inner.charAt(i);
            if (!inS && ch == '"' && !inD) { inD = true; rebuilt.push(ch); i++; continue; }
            if (inD && ch == '"') { inD = false; rebuilt.push(ch); i++; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; rebuilt.push(ch); i++; continue; }
            if (inS && ch == '\'') { inS = false; rebuilt.push(ch); i++; continue; }
            if (inD || inS) {
                // Inside quoted string: collapse \\" -> \"
                if (i + 2 < inner.length && inner.charAt(i) == '\\' && inner.charAt(i + 1) == '\\' && inner.charAt(i + 2) == '"') {
                    rebuilt.push('\\"');
                    i += 3;
                    continue;
                }
            }
            rebuilt.push(ch);
            i++;
        }
        return rebuilt.join("");
    }
}

#end
