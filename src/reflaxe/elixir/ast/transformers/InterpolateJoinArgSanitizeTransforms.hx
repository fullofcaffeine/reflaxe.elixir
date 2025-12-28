package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InterpolateJoinArgSanitizeTransforms
 *
 * WHAT
 * - Sanitizes ERaw strings containing Elixir string interpolation with
 *   Enum.join(<multi-statement block>, sep) inside #{...}. Wraps the first
 *   argument in an IIFE: Enum.join((fn -> <block> end).(), sep).
 *
 * WHY
 * - After StringInterpolation, complex list-building expressions may appear
 *   directly inside interpolation and are not valid as function arguments.
 *   Wrapping as an IIFE restores valid expression syntax without changing
 *   semantics.
 *
 * HOW
 * - For each ERaw string, scan all #{...} segments with balanced braces.
 *   Within each segment, detect Enum.join( ... , ...) and, if the first
 *   argument contains newlines or assignment markers, wrap it with an IIFE.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class InterpolateJoinArgSanitizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERaw(code) if (code != null && code.indexOf("#{") != -1 && code.indexOf("Enum.join(") != -1):
                    var updated = sanitizeRaw(code);
                    if (updated != code) makeASTWithMeta(ERaw(updated), n.metadata, n.pos) else n;
                case EString(value) if (value != null && value.indexOf("#{") != -1 && value.indexOf("Enum.join(") != -1):
                    var updatedStr = sanitizeRaw(value);
                    if (updatedStr != value) makeASTWithMeta(EString(updatedStr), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function sanitizeRaw(src: String): String {
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
            var fixed = fixEnumJoinFirstArg(inner);
            // Fallback: if the inner expression still contains multi-line or assignment
            // statements, wrap the entire interpolation in an IIFE to ensure validity.
            var trimmed = StringTools.trim(fixed);
            var needsIife = (fixed.indexOf('\n') != -1) || (fixed.indexOf('=') != -1 && fixed.indexOf("==") == -1);
            if (needsIife && !StringTools.startsWith(trimmed, '(fn ->')) {
                fixed = '(fn -> ' + fixed + ' end).()';
            }
            out.add("#{" + fixed + "}");
            i = k;
        }
        return out.toString();
    }

    static function fixEnumJoinFirstArg(expr: String): String {
        var start = 0;
        var out = expr;
        while (true) {
            var j = out.indexOf("Enum.join(", start);
            if (j == -1) break;
            var p = j + "Enum.join(".length;
            var depth = 1; var comma = -1; var q = p;
            while (q < out.length && depth > 0) {
                var ch = out.charAt(q);
                if (ch == '(') depth++; else if (ch == ')') depth--; else if (ch == ',' && depth == 1) { comma = q; break; }
                q++;
            }
            if (comma == -1) break;
            var arg1 = out.substr(p, comma - p);
            var needsWrap = (arg1.indexOf('\n') != -1) || (arg1.indexOf('=') != -1 && arg1.indexOf("==") == -1);
            if (needsWrap) {
                var wrapped = '(fn -> ' + arg1 + ' end).()';
                // Avoid double-wrapping: if arg1 already looks like an IIFE, keep it as-is
                var trimmedArg1 = StringTools.trim(arg1);
                if (StringTools.startsWith(trimmedArg1, '(fn ->') && StringTools.endsWith(trimmedArg1, ').()')) {
                    wrapped = arg1;
                }
                out = out.substr(0, p) + wrapped + out.substr(comma);
                start = p + wrapped.length + 1; // move forward
            } else {
                start = comma + 1;
            }
        }
        return out;
    }
}

#end
