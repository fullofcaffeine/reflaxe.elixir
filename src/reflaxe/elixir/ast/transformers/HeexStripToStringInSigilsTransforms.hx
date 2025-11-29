package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexStripToStringInSigilsTransforms
 *
 * WHAT
 * - Removes trailing `.to_string()` calls inside HEEx interpolations, e.g.:
 *   <%= @count.to_string() %> → <%= @count %>
 *
 * WHY
 * - HEEx interpolation auto-converts to iodata; `.to_string()` on numbers may
 *   be misinterpreted if introduced by earlier string-concat lowering.
 *
 * HOW
 * - For ESigil("H", content): regex-rewrite `<%= ... .to_string() %>` occurrences.
 */
class HeexStripToStringInSigilsTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = stripToString(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function stripToString(s:String):String {
        // Replace patterns like: <%= expr.to_string() %> → <%= expr %>
        var parts:Array<String> = [];
        var i = 0;
        while (i < s.length) {
            var start = s.indexOf("<%=", i);
            if (start == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, start - i));
            var endTag = s.indexOf("%>", start + 3);
            if (endTag == -1) { parts.push(s.substr(start)); break; }
            var inner = s.substr(start + 3, endTag - (start + 3));
            var trimmed = StringTools.trim(inner);
            if (StringTools.endsWith(trimmed, ".to_string()")) {
                trimmed = StringTools.trim(trimmed.substr(0, trimmed.length - ".to_string()".length));
            }
            parts.push("<%= " + trimmed + " %>");
            i = endTag + 2;
        }
        return parts.join("");
    }
}

#end
