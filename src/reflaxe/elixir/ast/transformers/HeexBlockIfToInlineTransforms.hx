package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexBlockIfToInlineTransforms
 *
 * WHAT
 * - Rewrites block-form HEEx if/else in content into inline-if when both branches are pure HTML
 *   (no nested EEx), e.g.:
 *   <%= if cond do %>...html...<% else %>...html...<% end %>
 *   → <%= if cond, do: "...html...", else: "...html..." %>
 *
 * WHY
 * - Matches snapshot style for simple conditional HTML; improves readability and parity.
 *
 * HOW
 * - For ESigil("H", content): scan segments, detect if/else blocks, ensure THEN/ELSE contain no
 *   '<%' markers, and replace with inline form using quoted strings.
 */
class HeexBlockIfToInlineTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = rewrite(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function rewrite(s:String):String {
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var open = s.indexOf("<%=", i);
            if (open == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, open - i));
            var close = s.indexOf("%>", open + 3);
            if (close == -1) { out.add(s.substr(open)); break; }
            var inner = StringTools.trim(s.substr(open + 3, close - (open + 3)));
            if (StringTools.startsWith(inner, "if ") && inner.indexOf(" do") != -1) {
                var cond = StringTools.trim(inner.substr(3, inner.indexOf(" do") - 3));
                // THEN content between %> and either <% else %> or <% end %>
                var thenStart = close + 2;
                var elseTag = s.indexOf("<% else %>", thenStart);
                var endTag = s.indexOf("<% end %>", thenStart);
                if (endTag == -1) { out.add(s.substr(open, (close+2)-open)); i = close+2; continue; }
                var thenEnd = (elseTag != -1 && elseTag < endTag) ? elseTag : endTag;
                var thenHtml = s.substr(thenStart, thenEnd - thenStart);
                var elseHtml: Null<String> = (elseTag != -1 && elseTag < endTag)
                    ? s.substr(elseTag + 10, endTag - (elseTag + 10)) : "";
                // Ensure no nested EEx AND branches are not HTML tags (avoid attribute/quote pitfalls)
                var branchesArePlainText = (thenHtml.indexOf('<') == -1 && (elseHtml == null || elseHtml.indexOf('<') == -1));
                if (thenHtml.indexOf("<%") == -1 && (elseHtml == null || elseHtml.indexOf("<%") == -1) && branchesArePlainText) {
                    out.add('<%= if ' + cond + ', do: ' + toQuoted(thenHtml) + ', else: ' + toQuoted(elseHtml) + ' %>');
                    i = endTag + 9;
                    continue;
                }
            }
            // Not a block-if to inline; copy segment
            out.add(s.substr(open, (close + 2) - open));
            i = close + 2;
        }
        return out.toString();
    }

    static function toQuoted(s:String):String {
        var t = StringTools.trim(s);
        // Already quoted? keep as-is
        if ((StringTools.startsWith(t, '"') && StringTools.endsWith(t, '"')) ||
            (StringTools.startsWith(t, "'") && StringTools.endsWith(t, "'"))) return t;
        // Escape inner quotes
        t = StringTools.replace(t, '"', '\\"');
        return '"' + t + '"';
    }
}

#end
