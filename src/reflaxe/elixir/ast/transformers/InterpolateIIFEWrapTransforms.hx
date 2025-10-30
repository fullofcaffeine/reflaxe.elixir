package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InterpolateIIFEWrapTransforms
 *
 * WHAT
 * - After StringInterpolation, wrap every interpolation body #{...} in an IIFE
 *   so the body is a single valid expression even if it contains statements.
 *
 * WHY
 * - Upstream desugarings can introduce multi-line/assignment blocks inside
 *   interpolation (e.g., Enum.join list-builders). Wrapping ensures validity
 *   regardless of earlier detection.
 */
class InterpolateIIFEWrapTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EString(value) if (value != null && value.indexOf("#{") != -1):
                    var updated = wrapAll(value);
                    if (updated != value) makeASTWithMeta(EString(updated), n.metadata, n.pos) else n;
                case ERaw(code) if (code != null && code.indexOf("#{") != -1):
                    var updated2 = wrapAll(code);
                    if (updated2 != code) makeASTWithMeta(ERaw(updated2), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function wrapAll(src: String): String {
        var out = new StringBuf();
        var i = 0;
        while (i < src.length) {
            var open = src.indexOf("#{", i);
            if (open == -1) { out.add(src.substr(i)); break; }
            out.add(src.substr(i, open - i));
            var k = open + 2; var depth = 1;
            while (k < src.length && depth > 0) {
                var ch = src.charAt(k);
                if (ch == '{') depth++; else if (ch == '}') depth--; k++;
            }
            var inner = src.substr(open + 2, (k - 1) - (open + 2));
            var trimmed = StringTools.trim(inner);
            if (!StringTools.startsWith(trimmed, '(fn ->')) {
                inner = '(fn -> ' + inner + ' end).()';
            }
            out.add("#{" + inner + "}");
            i = k;
        }
        return out.toString();
    }
}

#end

