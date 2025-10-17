package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * HeexPreferTypedEmissionTransforms
 *
 * WHAT
 * - Prefer emitting ~H content from the typed HEEx AST (EFragment/EAttribute children)
 *   attached by the builder instead of relying on string rewrites.
 *
 * WHY
 * - Moves us toward deterministic, typed HEEx generation for attributes/children so that
 *   linters and future transforms operate on structure, not brittle strings. This is a
 *   guarded step toward retiring TemplateHelpers string paths.
 *
 * HOW
 * - For ESigil("H", content, modifiers) nodes, when metadata.heexAST is present and the
 *   original content does not contain control constructs that are still handled by string
 *   passes (e.g., <if/else> tags or <% ... %> blocks), rebuild the content by printing the
 *   typed nodes via ElixirASTPrinter and replace the ESigil content.
 * - Strictly gated by -D hxx_prefer_efragment and by a conservative content check to avoid
 *   interfering with control‑tag/string transforms. This ensures zero behavior change where
 *   typed emission would not yet be equivalent.
 *
 * EXAMPLES
 * Haxe:
 *   @:heex '<div class={@active ? "on" : "off"} phx-click={@click}></div>'
 * Before:
 *   ~H"""<div class={if @active, do: "on", else: "off"} phx-click={@click}></div>"""
 * After (typed, identical output):
 *   ~H"""<div class={if @active, do: "on", else: "off"} phx-click={@click}></div>"""
 */
class HeexPreferTypedEmissionTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        #if !hxx_prefer_efragment
        return ast;
        #end
        return ElixirASTTransformer.transformNode(ast, function(n) {
            switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    // Require typed nodes from builder
                    var meta = n.metadata;
                    if (meta == null) return n;
                    var dyn: Dynamic = meta;
                    if (!Reflect.hasField(dyn, "heexAST")) return n;
                    var nodes: Array<ElixirAST> = Reflect.field(dyn, "heexAST");
                    if (nodes == null || nodes.length == 0) return n;

                    // Skip when content contains control tags/blocks still handled by string passes
                    var s = content;
                    if (
                        // Skip when control tags are present
                        s.indexOf("<if") != -1 || s.indexOf("</if>") != -1 || s.indexOf("<else") != -1 ||
                        // Skip when any EEx is present (attribute or block) to avoid partial handling for now
                        s.indexOf("<%=") != -1 || s.indexOf("<% ") != -1 || s.indexOf("<% if") != -1 || s.indexOf("<% else") != -1 || s.indexOf("<% end") != -1
                    ) {
                        return n;
                    }

                    // Rebuild content from typed fragments using HEEx-aware rendering
                    var rendered = [for (child in nodes) renderHeex(child)].join("");
                    var replacement = makeASTWithMeta(ESigil(type, rendered, modifiers), n.metadata, n.pos);
                    return replacement;
                default:
            }
            return n;
        });
    }

    // HEEx-aware renderer (do not quote EString children)
    static function renderHeex(node: ElixirAST): String {
        return switch (node.def) {
            case EFragment(tag, attributes, children):
                var attrStr = renderAttrs(attributes);
                var childStr = [for (c in children) renderHeex(c)].join("");
                '<' + tag + attrStr + '>' + childStr + '</' + tag + '>';
            case EString(v):
                v;
            default:
                // Fallback: embed as interpolation
                '<%= ' + ElixirASTPrinter.print(node, 0) + ' %>';
        }
    }

    static function renderAttrs(attrs: Array<EAttribute>): String {
        if (attrs == null || attrs.length == 0) return '';
        var parts: Array<String> = [];
        for (a in attrs) {
            var val = switch (a.value.def) {
                case EString(s): '"' + s + '"';
                default: '{' + ElixirASTPrinter.print(a.value, 0) + '}';
            };
            parts.push(a.name + '=' + val);
        }
        return parts.length > 0 ? (' ' + parts.join(' ')) : '';
    }
}

#end
