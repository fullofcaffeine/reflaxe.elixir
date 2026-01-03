package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexRenderHelperCallWrapTransforms
 *
 * WHAT
 * - Inside ~H sigils, wrap helper calls like `<%= render_* ( ... ) %>` with
 *   `Phoenix.HTML.raw(...)` so returned strings are treated as safe HTML until
 *   those helpers are migrated to return ~H.
 *
 * WHY
 * - Prevents escaped literal tags when embedding helpers that still emit strings.
 *   This is a transitional safety to keep the UI functional while helpers migrate.
 *
 * HOW
 * - For ESigil("H", content):
 *   - Replace occurrences of `<%= <call> %>` where `<call>` matches `render_[a-z_0-9]+(…)`
 *     and is not already wrapped in `Phoenix.HTML.raw(` with
 *     `<%= Phoenix.HTML.raw(<call>) %>`.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexRenderHelperCallWrapTransforms {
    static function wrap(content:String):String {
        if (content == null) return content;
        var parts:Array<String> = [];
        var i = 0;
        while (i < content.length) {
            var idx = content.indexOf("<%=", i);
            if (idx == -1) { parts.push(content.substr(i)); break; }
            parts.push(content.substr(i, idx - i));
            var j = idx + 3; // after <%= 
            // copy whitespace
            while (j < content.length && ~/^\s$/.match(content.charAt(j))) j++;
            var startExpr = j;
            // find closing %>
            var end = content.indexOf("%>", j);
            if (end == -1) { parts.push(content.substr(idx)); break; }
            var expr = content.substr(startExpr, end - startExpr);
            var trimmed = StringTools.trim(expr);
            var alreadyRaw = StringTools.startsWith(trimmed, "Phoenix.HTML.raw(");
            var isRenderHelper = ~/^render_[a-z0-9_]+\s*\(/.match(trimmed);
            // `render_slot/2` returns a Phoenix.LiveView.Rendered struct and must not be wrapped
            // in Phoenix.HTML.raw/1 (it will crash at runtime).
            var isRenderSlot = ~/^render_slot\s*\(/.match(trimmed);
            if (!alreadyRaw && isRenderHelper && !isRenderSlot) {
                parts.push("<%= Phoenix.HTML.raw(" + expr + ") %>");
            } else {
                // Copy original segment unchanged
                parts.push(content.substr(idx, (end + 2) - idx));
            }
            i = end + 2;
        }
        return parts.join("");
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, mods) if (type == "H"):
                    var updated = wrap(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, mods), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }
}

#end
