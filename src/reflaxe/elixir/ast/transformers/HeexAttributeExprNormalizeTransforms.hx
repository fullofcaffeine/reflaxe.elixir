package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * HeexAttributeExprNormalizeTransforms
 *
 * WHAT
 * - Normalizes attribute-level EEx interpolations inside ~H sigils into HEEx attribute
 *   expressions with braces: name={expr}.
 * - Handles two common shapes:
 *   1) Simple interpolation: name=<%= expr %> → name={expr}
 *   2) Inline conditional block: name=<% if cond do %>then<% else %>else<% end %>
 *      → name={if cond, do: "then", else: "else"}
 * - Also unwraps inspect(): name=<%= inspect((expr)) %> → name={expr}
 *
 * WHY
 * - Transitional path until attribute-level EFragment is the default representation.
 * - Ensures idiomatic HEEx attributes across the pipeline, avoiding StringBuf/inspect artifacts.
 *
 * HOW
 * - Runs over ESigil("H", content) and applies conservative regex rewrites.
 * - Only affects attribute contexts (immediately preceding '=' without crossing '>').
 * - Does not attempt full HTML parsing; complements future EFragment work.
 *
 * EXAMPLES
 * Haxe:
 *   HXX.hxx('<option selected=${assigns.sort_by == "created"} />')
 * HEEx before:
 *   <option selected=<%= inspect((@sort_by == "created")) %> />
 * HEEx after:
 *   <option selected={@sort_by == "created"} />
 */
class HeexAttributeExprNormalizeTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return normalize(ast, null);
    }

    public static function contextualPass(ast: ElixirAST, ctx: reflaxe.elixir.CompilationContext): ElixirAST {
        return normalize(ast, ctx);
    }

    static function normalize(ast: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = rewriteHeexAttributes(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function rewriteHeexAttributes(s: String): String {
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var j = s.indexOf("<%", i);
            if (j == -1) { parts.push(s.substr(i)); break; }

            // Determine if this <% ... %> is directly after an '=' in an attribute context,
            // without crossing a tag close '>'.
            var k = j - 1; var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }
            if (k < i || seenGt || s.charAt(k) != '=') {
                // Not an attribute context; copy and continue past this EEx opener
                parts.push(s.substr(i, j - i));
                parts.push("<%");
                i = j + 2;
                continue;
            }

            // We're in an attribute value context. Copy prefix up to '='
            parts.push(s.substr(i, (k - i) + 1));
            // Optional opening quote after '='
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == '"' || s.charAt(vpos) == '\'')) { quote = s.charAt(vpos); vpos++; }
            // Expect vpos == j
            if (vpos != j) {
                // Unexpected; emit as-is
                parts.push(s.substr(k + 1, j - (k + 1)));
                parts.push("<%");
                i = j + 2; continue;
            }

            // Case A: <%= expr %>
            if (j + 3 <= s.length && s.charAt(j + 2) == '=') {
                var end = s.indexOf("%>", j + 3);
                if (end == -1) { parts.push(s.substr(i)); break; }
                var expr = StringTools.trim(s.substr(j + 3, end - (j + 3)));
                // Special handling: <%= if cond do %>then<% else %>else<% end %>
                if (StringTools.startsWith(expr, "if ") && StringTools.endsWith(expr, " do")) {
                    var condStr = StringTools.trim(expr.substr(3, expr.length - 3 - 3)); // between "if " and " do"
                    var thenStartPos = end + 2;
                    var elseMarkerPos = s.indexOf("<% else %>", thenStartPos);
                    var endMarkerPos = s.indexOf("<% end %>", thenStartPos);
                    if (endMarkerPos == -1) { parts.push(s.substr(i)); break; }
                    var thenEndPos = (elseMarkerPos != -1 && elseMarkerPos < endMarkerPos) ? elseMarkerPos : endMarkerPos;
                    var thenContent = StringTools.trim(s.substr(thenStartPos, thenEndPos - thenStartPos));
                    var elseContent: Null<String> = (elseMarkerPos != -1 && elseMarkerPos < endMarkerPos) ? StringTools.trim(s.substr(elseMarkerPos + 10, endMarkerPos - (elseMarkerPos + 10))) : null;
                    if (!isQuoted(thenContent)) thenContent = quoteWrap(thenContent);
                    if (elseContent != null && !isQuoted(elseContent)) elseContent = quoteWrap(elseContent);
                    parts.push('{'); parts.push('if ' + condStr + ', do: ' + thenContent + (elseContent != null ? ', else: ' + elseContent : '')); parts.push('}');
                    var postEndPos = endMarkerPos + 9; if (quote != null && postEndPos < s.length && s.charAt(postEndPos) == quote) postEndPos++;
                    i = postEndPos;
                    continue;
                } else {
                    // unwrap inspect((...))
                    var rx = ~/^inspect\((.*)\)$/;
                    if (rx.match(expr)) expr = StringTools.trim(rx.matched(1));
                    parts.push('{'); parts.push(expr); parts.push('}');
                    var p = end + 2;
                    // Skip closing quote if present
                    if (quote != null && p < s.length && s.charAt(p) == quote) p++;
                    i = p;
                    continue;
                }
            }

            // Case B: <% if cond do %>then<% else %>else<% end %>
            var ifStart = s.indexOf("if", j + 2);
            var doPos = s.indexOf("do %>", j + 2);
            if (ifStart != -1 && doPos != -1 && ifStart < doPos) {
                var condStr = StringTools.trim(s.substr(ifStart + 2, (doPos) - (ifStart + 2)));
                var thenStart = doPos + 5;
                var elseOpen = s.indexOf("<% else %>", thenStart);
                var endOpen = s.indexOf("<% end %>", thenStart);
                if (endOpen == -1) { parts.push(s.substr(i)); break; }
                var thenEnd = (elseOpen != -1 && elseOpen < endOpen) ? elseOpen : endOpen;
                var thenHtml = StringTools.trim(s.substr(thenStart, thenEnd - thenStart));
                var elseHtml = (elseOpen != -1 && elseOpen < endOpen) ? StringTools.trim(s.substr(elseOpen + 10, endOpen - (elseOpen + 10))) : null;
                // Quote then/else if not already quoted
                if (!isQuoted(thenHtml)) thenHtml = quoteWrap(thenHtml);
                if (elseHtml != null && !isQuoted(elseHtml)) elseHtml = quoteWrap(elseHtml);
                parts.push('{'); parts.push('if ' + condStr + ', do: ' + thenHtml + (elseHtml != null ? ', else: ' + elseHtml : '')); parts.push('}');
                var p2 = endOpen + 9; if (quote != null && p2 < s.length && s.charAt(p2) == quote) p2++;
                i = p2;
                continue;
            }

            // Fallback: not a recognized block; emit as-is
            parts.push(s.substr(k + 1, j - (k + 1)));
            parts.push("<%");
            i = j + 2;
        }
        return parts.join("");
    }

    static inline function isQuoted(s: String): Bool {
        return (
            (StringTools.startsWith(s, "\"") && StringTools.endsWith(s, "\"")) ||
            (StringTools.startsWith(s, "'") && StringTools.endsWith(s, "'"))
        );
    }
    static inline function quoteWrap(s: String): String {
        var t = StringTools.replace(s, "\"", "\\\"");
        return "\"" + t + "\"";
    }
}

#end
