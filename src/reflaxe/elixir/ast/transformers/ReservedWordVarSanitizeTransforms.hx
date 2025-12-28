package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReservedWordVarSanitizeTransforms
 *
 * WHAT
 * - Renames variables that collide with Elixir reserved words (e.g., fn) to a
 *   safe variant (e.g., fn_). Applies to both patterns (PVar) and EVar refs.
 *
 * WHY
 * - Some generic passes can synthesize names that inadvertently match
 *   keywords. This breaks parsing and yields misleading terminator errors.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ReservedWordVarSanitizeTransforms {
    static final reserved = [
        "fn", "do", "end", "case", "cond", "try", "rescue", "catch", "after",
        "receive", "quote", "unquote", "when", "and", "or", "not"
    ];

    static inline function safe(name:String):String {
        return reserved.indexOf(name) >= 0 ? (name + "_") : name;
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v): makeAST(EVar(safe(v)));
                case EMatch(pattern, expr):
                    var newPat = sanitizePattern(pattern);
                    if (newPat != pattern) makeAST(EMatch(newPat, expr)) else n;
                case EBinary(EBinaryOp.Match, left, right):
                    var newLeft = switch (left.def) {
                        case EVar(v): makeAST(EVar(safe(v)));
                        default: left;
                    };
                    if (newLeft != left) makeAST(EBinary(EBinaryOp.Match, newLeft, right)) else n;
                default:
                    n;
            }
        });
    }

    static function sanitizePattern(p: EPattern): EPattern {
        return switch (p) {
            case PVar(n): PVar(safe(n));
            case PCons(h, t): PCons(sanitizePattern(h), sanitizePattern(t));
            case PTuple(elems): PTuple([for (e in elems) sanitizePattern(e)]);
            case PList(elems): PList([for (e in elems) sanitizePattern(e)]);
            default: p;
        }
    }
}

#end
