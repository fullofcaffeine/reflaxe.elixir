package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexSimplifyIIFEInInterpolations
 *
 * WHAT
 * - Simplify trivial IIFE wrappers inside HEEx interpolations: <%= (fn -> expr end).() %> → <%= expr %>
 *
 * WHY
 * - The printer sometimes wraps interpolation bodies in an IIFE to guarantee single-expression validity.
 *   For simple expressions (like @assigns access), this is unnecessary and hurts readability and snapshots.
 *
 * HOW
 * - String-level rewrite on ESigil("H", content) bodies using conservative patterns.
 *   Only removes the outer (fn -> … end).() around a single interpolation with no nested %>.
 */
class HeexSimplifyIIFEInInterpolations {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ESigil(type, content, modifiers) if (type == "H" && content != null && content.indexOf("<%=") != -1):
                    var simplified = simplify(content);
                    if (simplified != content) makeASTWithMeta(ESigil(type, simplified, modifiers), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function simplify(s:String):String {
        // Fast path: do nothing if no obvious IIFE markers
        if (s.indexOf("(fn ->") == -1 || s.indexOf("end).()") == -1) return s;
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var start = s.indexOf("<%=", i);
            if (start == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, start - i));
            var endTag = s.indexOf("%>", start + 3);
            if (endTag == -1) { out.add(s.substr(start)); break; }
            var inner = StringTools.trim(s.substr(start + 3, endTag - (start + 3)));
            // Recognize pattern: (fn -> <expr> end).()
            if (StringTools.startsWith(inner, "(fn ->") && StringTools.endsWith(inner, " end).()")) {
                // Exact pattern: (fn -> <expr> end).()
                var mid = StringTools.trim(inner.substr(6, inner.length - 6 - " end).()".length));
                // Write simplified interpolation
                out.add("<%= ");
                out.add(mid);
                out.add(" %>");
            } else {
                out.add(s.substr(start, (endTag + 2) - start));
            }
            i = endTag + 2;
        }
        return out.toString();
    }
}

#end
