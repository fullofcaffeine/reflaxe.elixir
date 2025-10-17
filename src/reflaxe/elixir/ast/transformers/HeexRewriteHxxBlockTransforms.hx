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
 */
class HeexRewriteHxxBlockTransforms {
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
        var out = s;
        // Replace <%= HXX.block("...") %> with inner literal
        out = replaceBlock(out, "HXX.block");
        out = replaceBlock(out, "hxx.HXX.block");
        return out;
    }

    static function replaceBlock(s:String, callee:String):String {
        var i = 0;
        var res = new StringBuf();
        while (i < s.length) {
            var open = s.indexOf("<%=", i);
            if (open == -1) { res.add(s.substr(i)); break; }
            res.add(s.substr(i, open - i));
            var close = s.indexOf("%>", open + 3);
            if (close == -1) { res.add(s.substr(open)); break; }
            var inner = StringTools.trim(s.substr(open + 3, close - (open + 3)));
            // Expect callee("...")
            if (StringTools.startsWith(inner, callee + "(")) {
                var paren = inner.indexOf('(');
                var arg = StringTools.trim(inner.substr(paren + 1));
                if (StringTools.endsWith(arg, ")")) arg = arg.substr(0, arg.length - 1);
                var un = unquote(arg);
                if (un != null) {
                    res.add(un);
                    i = close + 2;
                    continue;
                }
            }
            // Not a match; copy original segment
            res.add(s.substr(open, (close + 2) - open));
            i = close + 2;
        }
        return res.toString();
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
}

#end

