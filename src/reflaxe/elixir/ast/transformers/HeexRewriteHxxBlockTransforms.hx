package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexRewriteHxxBlockTransforms
 *
 * WHAT
 * - Rewrites occurrences of `<%= HXX.block("...") %>` (and `hxx.HXX.block`) inside ~H sigils
 *   into literal HTML content to avoid helper residue in final HEEx.
 *
 * WHY
 * - HXX.block('...') is a compile-time helper for embedding raw HTML. Residual calls inside ~H
 *   degrade readability and may break snapshot parity. Inlining the HTML is the correct end state.
 *
 * HOW
 * - For ESigil("H", content): string pattern replacements that are safe and conservative:
 *   • `<%=\s*HXX.block("...")\s*%>` → `...`
 *   • `<%=\s*hxx\.HXX\.block("...")\s*%>` → `...`
 * - Supports both single and double quotes, does not unescape inner content.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexRewriteHxxBlockTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = rewrite(content);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;
                case ERaw(code):
                    if (code != null && code.indexOf("~H\"\"\"") != -1) {
                        var updatedCode = replaceNestedHeexSigil(code);
                        if (updatedCode != code) return makeASTWithMeta(ERaw(updatedCode), n.metadata, n.pos);
                    }
                    n;
                default:
                    n;
            }
        });
    }

    static function rewrite(s:String):String {
        var out = s;
        // Replace <%= HXX.block("...") %> with inner literal
        out = replaceBlock(out, "HXX.block");
        out = replaceBlock(out, "hxx.HXX.block");
        // Also strip nested ~H sigils rendered inside ~H: <%= ~H"""...""" %> -> inline body
        out = replaceNestedHeexSigil(out);
        // Avoid inline-if regex rewrites; rely on structured conversions
        return out;
    }

    static function replaceBlock(s:String, callee:String):String {
        var i = 0;
        var parts:Array<String> = [];
        while (i < s.length) {
            var open = s.indexOf("<%=", i);
            if (open == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, open - i));
            var close = s.indexOf("%>", open + 3);
            if (close == -1) { parts.push(s.substr(open)); break; }
            var inner = StringTools.trim(s.substr(open + 3, close - (open + 3)));
            // Expect callee("...")
            if (StringTools.startsWith(inner, callee + "(")) {
                var paren = inner.indexOf('(');
                var arg = StringTools.trim(inner.substr(paren + 1));
                if (StringTools.endsWith(arg, ")")) arg = arg.substr(0, arg.length - 1);
                var un = unquote(arg);
                if (un != null) {
                    parts.push(un);
                    i = close + 2;
                    continue;
                }
            }
            // Not a match; copy original segment
            parts.push(s.substr(open, (close + 2) - open));
            i = close + 2;
        }
        return parts.join("");
    }

    static function unquote(x:String):Null<String> {
        var t = StringTools.trim(x);
        if (t.length >= 2) {
            var a = t.charAt(0);
            var b = t.charAt(t.length - 1);
            if ((a == '"' && b == '"') || (a == '\'' && b == '\'')) {
                return t.substr(1, t.length - 2);
            }
        }
        return null;
    }

    // Replace `<%= ~H""" ... """ %>` with just the inner `...` body to avoid nested ~H
    static function replaceNestedHeexSigil(s:String):String {
        var i = 0;
        var parts:Array<String> = [];
        while (i < s.length) {
            var open = s.indexOf("<%=", i);
            if (open == -1) { parts.push(s.substr(i)); break; }
            parts.push(s.substr(i, open - i));
            var close = s.indexOf("%>", open + 3);
            if (close == -1) { parts.push(s.substr(open)); break; }
            var inner = StringTools.trim(s.substr(open + 3, close - (open + 3)));
            if (StringTools.startsWith(inner, "~H\"\"\"")) {
                // Find body between the first and second triple quotes
                var start = inner.indexOf("\"\"\"");
                if (start != -1) {
                    var bodyStart = start + 3;
                    var bodyEnd = inner.indexOf("\"\"\"", bodyStart);
                    if (bodyEnd != -1) {
                        var body = inner.substr(bodyStart, bodyEnd - bodyStart);
                        parts.push(body);
                        i = close + 2;
                        continue;
                    }
                }
            }
            // Not a nested ~H; copy original segment
            parts.push(s.substr(open, (close + 2) - open));
            i = close + 2;
        }
        return parts.join("");
    }

    // Note: Do not rewrite inline-if forms inside ~H here; canonical snapshots
    // expect the inline `, do:` syntax to remain unchanged.

    static function indexOfTopLevel(s:String, token:String):Int {
        var depth = 0;
        var inS = false, inD = false;
        for (idx in 0...s.length - token.length + 1) {
            var ch = s.charAt(idx);
            if (!inS && ch == '"' && !inD) { inD = true; continue; }
            else if (inD && ch == '"') { inD = false; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; continue; }
            else if (inS && ch == '\'') { inS = false; continue; }
            if (inS || inD) continue;
            if (ch == '(' || ch == '{' || ch == '[') depth++;
            else if (ch == ')' || ch == '}' || ch == ']') depth--;
            if (depth != 0) continue;
            if (s.substr(idx, token.length) == token) return idx;
        }
        return -1;
    }
    static function extractQuoted(s:String):Null<{value:String, length:Int}> {
        if (s.length == 0) return null;
        var quote = s.charAt(0);
        if (quote != '"' && quote != '\'') return null;
        var i = 1;
        while (i < s.length) {
            var ch = s.charAt(i);
            var prev = s.charAt(i - 1);
            if (ch == quote && prev != '\\') {
                var val = s.substr(1, i - 1);
                // Unescape common sequences inside HTML content
                val = StringTools.replace(val, "\\\"", '"');
                val = StringTools.replace(val, "\\'", "'");
                val = StringTools.replace(val, "\\\\", "\\");
                return { value: val, length: i + 1 };
            }
            i++;
        }
        return null;
    }
}

#end
