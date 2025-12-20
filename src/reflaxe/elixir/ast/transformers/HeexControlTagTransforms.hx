package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexControlTagTransforms
 *
 * WHAT
 * - Rewrites HXX control tags to proper HEEx control-flow blocks inside ~H sigils.
 * - Currently supports: <if {cond}> ... (<else> ...)? </if>.
 *
 * WHY
 * - HXX authoring must be pure Haxe/HXX without embedding target HEEx/EEx syntax.
 *   Large conditional HTML chunks expressed as inline expressions (e.g., ternary or
 *   inline `if ..., do: "<html>"`) are brittle and can break HEEx tokenization
 *   due to quoting/attribute syntax. Rewriting control tags into block HEEx yields
 *   idiomatic, robust templates and matches the coconut.ui pattern developers expect.
 *
 * HOW
 * - End-to-end flow:
 *   1) Author writes HXX via HXX.hxx(' ... ') with HXX control tags, e.g.:
 *      <if {assigns.show_form}> ... <else> ... </if>
 *   2) ElixirASTBuilder collects the HXX string and emits an ESigil("H", content, "")
 *      via TemplateHelpers.collectTemplateContent().
 *   3) HeexStringReturnToSigilTransforms ensures helper-returned HTML strings are
 *      materialized as ~H sigils (so all templates are in ESigil form).
 *   4) HeexControlTagTransforms runs over ESigil("H", content) and rewrites control tags
 *      to block HEEx using a conservative regex that handles whitespace and newlines.
 *      - <if {cond}> thenHtml </if> → <%= if cond do %> thenHtml <% end %>
 *      - <if {cond}> thenHtml <else> elseHtml </if> → block with <% else %>
 *      - `assigns.` inside conditions is mapped to `@` for HEEx idioms.
 *   5) Subsequent passes (e.g., HeexAssignsBindRepair) operate on clean HEEx blocks.
 *
 * EXAMPLES
 * Haxe (HXX):
 *   return HXX.hxx('
 *     <div>
 *       <if {assigns.show_form}>
 *         <form phx-submit="create_todo"> ... </form>
 *       <else>
 *         <p>Hidden</p>
 *       </if>
 *     </div>
 *   ');
 *
 * Elixir ~H (before this pass):
 *   ~H"""
 *   <div>
 *     <if {@show_form}>
 *       <form phx-submit="create_todo"> ... </form>
 *     <else>
 *       <p>Hidden</p>
 *     </else>
 *     </if>
 *   </div>
 *   """
 *
 * Elixir ~H (after this pass):
 *   ~H"""
 *   <div>
 *     <%= if @show_form do %>
 *       <form phx-submit="create_todo"> ... </form>
 *     <% else %>
 *       <p>Hidden</p>
 *     <% end %>
 *   </div>
 *   """
 *
 * ORDERING
 * - Registered late in the pipeline, after ~H sigils are materialized (HeexStringReturnToSigilTransforms)
 *   and again as a final sweep to catch any ~H content introduced by later passes.
 * - The transform is idempotent; if no control tags are present, it returns the node unchanged.
 *
 * LIMITATIONS & NEXT STEPS
 * - Current implementation focuses on <if>/<else>. Future work will parse HXX to EFragment
 *   nodes for attribute-level expression typing and add <for>/<switch> compilation.
 * - Nested <if> blocks are not fully handled by this minimal regex approach; the structured
 *   fragment builder will address nesting robustly.
 *
 * CROSS-REFERENCES
 * - TemplateHelpers.collectTemplateContent: builds ESigil("H", ...) from HXX.hxx() strings
 * - HeexStringReturnToSigilTransforms: ensures helper-returned HTML becomes ~H
 * - ElixirASTPassRegistry: pass ordering (late + final sweep)
 * - Tests: test/snapshot/phoenix/hxx_block_if (block conditional), hxx_inline_expr (assigns)
 */
class HeexControlTagTransforms {
    /** Public helper to rewrite control tags in-place (builder-time use). */
    public static function rewrite(content:String):String {
        if (content == null) return content;
        #if hxx_instrument
        var t0 = haxe.Timer.stamp();
        #end
        var lowered = reflaxe.elixir.ast.TemplateHelpers.rewriteForBlocks(content);
        // Inside ~H, Elixir string interpolation (`#{...}` / `${...}`) is literal text.
        // Normalize all HXX-style interpolations to HEEx `<%= ... %>` so templates render correctly.
        lowered = reflaxe.elixir.ast.TemplateHelpers.rewriteInterpolations(lowered);
        if (lowered.indexOf("<if") == -1) return lowered;
        var out = rewriteControlTags(lowered);
        #if hxx_instrument
        var dt = Std.int((haxe.Timer.stamp() - t0) * 1000);
        // DISABLED: trace('[HXX-INSTR] controlTags: ms=' + dt + ' len=' + (content != null ? content.length : 0));
        #end
        return out;
    }
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var lowered = reflaxe.elixir.ast.TemplateHelpers.rewriteForBlocks(content);
                    lowered = reflaxe.elixir.ast.TemplateHelpers.rewriteInterpolations(lowered);
                    var updated = rewriteControlTags(lowered);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                case ERaw(code):
                    // Handle ~H in raw code blocks as well
                    if (code != null && code.indexOf("~H\"\"\"") != -1) {
                        var idx = code.indexOf("~H\"\"\"");
                        var start = idx + 4; // after ~H
                        var open = code.indexOf('"', idx);
                        if (open != -1) {
                            // find the triple quotes start
                            var triple = code.indexOf("\"\"\"", idx);
                            if (triple != -1) {
                                var contentStart = triple + 3;
                                var contentEnd = code.indexOf("\"\"\"", contentStart);
                                if (contentEnd != -1) {
                                    var before = code.substr(0, contentStart);
                                    var body = code.substr(contentStart, contentEnd - contentStart);
                                    var after = code.substr(contentEnd);
                                    var updatedBody = rewriteControlTags(reflaxe.elixir.ast.TemplateHelpers.rewriteInterpolations(body));
                                    if (updatedBody != body) return makeASTWithMeta(ERaw(before + updatedBody + after), n.metadata, n.pos);
                                }
                            }
                        }
                    }
                    n;
                default:
                    n;
            }
        });
    }

    public static function rewriteControlTags(s:String):String {
        if (s == null || s.indexOf("<if") == -1) return s;
        var parts:Array<String> = [];
        var i = 0;
        #if hxx_instrument
        var iters = 0;
        #end
        while (i < s.length) {
            #if hxx_instrument iters++; #end
            var idx = s.indexOf("<if", i);
            if (idx == -1) { parts.push(s.substr(i)); break; }
            // copy prefix
            parts.push(s.substr(i, idx - i));
            var j = idx + 3; // after '<if'
            // skip whitespace
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            // expect '{'
            if (j >= s.length || s.charAt(j) != '{') { parts.push("<if"); i = idx + 3; continue; }
            // parse balanced braces
            var braceStart = j; j++;
            var braceDepth = 1;
            while (j < s.length && braceDepth > 0) {
                var ch = s.charAt(j);
                if (ch == '{') braceDepth++; else if (ch == '}') braceDepth--; j++;
            }
            if (braceDepth != 0) { parts.push(s.substr(idx)); break; }
            var braceEnd = j - 1;
            // skip whitespace to '>'
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '>') { parts.push(s.substr(idx, j - idx)); i = j + 1; continue; }
            var openEnd = j + 1;
            var cond = StringTools.trim(s.substr(braceStart + 1, braceEnd - (braceStart + 1)));
            // If the condition was produced via interpolation helpers, it can arrive as:
            //   <if {<%= expr %>}> ... </if>
            // Unwrap to keep generated HEEx valid.
            var single = ~/^<%=\s*(.*?)\s*%>$/s;
            if (single.match(cond)) cond = StringTools.trim(single.matched(1));
            // Normalize common Haxe-ish syntax inside control tags.
            cond = StringTools.replace(cond, "assigns.", "@");
            cond = ~/\bnull\b/g.replace(cond, "nil");
            var lenProp = ~/(@?[A-Za-z0-9_\.]+)\.length\b/g;
            cond = lenProp.map(cond, function (re) {
                return 'length(' + re.matched(1) + ')';
            });
            // find matching </if>, track nested <if
            var k = openEnd;
            var depth = 1;
            var elsePos = -1;
            while (k < s.length && depth > 0) {
                // find next tag-like token quickly
                var nextIf = s.indexOf("<if", k);
                var nextElse = s.indexOf("<else>", k);
                var nextClose = s.indexOf("</if>", k);
                var next = -1;
                var tag = 0; // 1=if,2=else,3=close
                if (nextIf != -1) { next = nextIf; tag = 1; }
                if (nextElse != -1 && (next == -1 || nextElse < next)) { next = nextElse; tag = 2; }
                if (nextClose != -1 && (next == -1 || nextClose < next)) { next = nextClose; tag = 3; }
                if (next == -1) break;
                if (tag == 1) { depth++; k = next + 3; }
                else if (tag == 2 && depth == 1 && elsePos == -1) { elsePos = next; k = next + 6; }
                else if (tag == 3) { depth--; k = next + 5; }
                else k = next + 1;
            }
            if (depth != 0) { parts.push(s.substr(idx)); break; }
            var closeIdx = k - 5; // position of '<' in </if>
            var thenStart = openEnd;
            var thenEnd = elsePos != -1 ? elsePos : closeIdx;
            var elseStart = elsePos != -1 ? (elsePos + 6) : -1;
            var elseEnd = closeIdx;
            var thenHtml = s.substr(thenStart, thenEnd - thenStart);
            var elseHtml = elseStart != -1 ? s.substr(elseStart, elseEnd - elseStart) : null;
            // Recursively rewrite nested <if>/<else> blocks in the branches so authoring can
            // freely nest control tags without leaking literal <if> elements into HEEx output.
            thenHtml = rewriteControlTags(thenHtml);
            if (elseHtml != null) elseHtml = rewriteControlTags(elseHtml);
            parts.push('<%= if ' + cond + ' do %>');
            parts.push(thenHtml);
            if (elseHtml != null && StringTools.trim(elseHtml) != "") {
                parts.push('<% else %>');
                parts.push(elseHtml);
            }
            parts.push('<% end %>');
            // advance i to after closing tag
            var afterClose = s.indexOf('>', closeIdx + 1);
            i = (afterClose == -1) ? s.length : afterClose + 1;
        }
        #if hxx_instrument
        // DISABLED: trace('[HXX-INSTR] controlTags.loopIters=' + iters + ' len=' + (s != null ? s.length : 0));
        #end
        return parts.join("");
    }
}

#end
