package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BinaryOperandBlockToIIFETransforms
 *
 * WHAT
 * - Wrap multi-statement blocks used as operands of binary operators in an IIFE
 *   to ensure they are valid expressions (e.g., for string concatenation <>).
 *
 * WHY
 * - Desugared code can leave EBlock/EDo in expression position. Elixir requires
 *   a single expression there.
 */
class BinaryOperandBlockToIIFETransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(op, left, right):
                    var newLeft = wrapIfNeeded(left);
                    var newRight = wrapIfNeeded(right);
                    if (newLeft != left || newRight != right) makeASTWithMeta(EBinary(op, newLeft, newRight), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static inline function wrapIfNeeded(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EBlock(_) | EDo(_):
                makeIIFE(e);
            case EParen(inner):
                switch (inner.def) {
                    case EBlock(_) | EDo(_): makeIIFE(inner);
                    default: e;
                }
            default:
                e;
        }
    }

    static inline function makeIIFE(body: ElixirAST): ElixirAST {
        return makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: body }])), "", []));
    }
}

#end

