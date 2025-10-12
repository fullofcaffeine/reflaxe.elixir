package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * NoOpArithmeticCleanup
 *
 * WHAT
 * - Removes spurious arithmetic expressions like `0 + 1` that appear as standalone
 *   statements in blocks (typically artifacts from reduce_while lowering patterns).
 *
 * WHY
 * - These expressions have no side effects and clutter generated code, triggering
 *   warnings or distracting human readers. Eliminating them improves readability
 *   without affecting semantics.
 *
 * HOW
 * - Walk EBlock nodes and filter out any statement that exactly matches
 *   `EBinary(Add, EInteger(0), EInteger(1))`.
 * - Conservative: only remove when the expression is a direct block statement.
 *   We do not rewrite inside larger expressions to avoid changing semantics.
 *
 * EXAMPLES
 * Before:
 *   { ...
 *     0 + 1
 *     if todo.id == id, do: todo
 *     ...
 *   }
 * After:
 *   { ...
 *     if todo.id == id, do: todo
 *     ...
 *   }
 */
class NoOpArithmeticCleanup {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var filtered: Array<ElixirAST> = [];
                    for (s in stmts) switch (s.def) {
                        case EBinary(Add, {def: EInteger(0)}, {def: EInteger(1)}):
                            // drop
                        default:
                            filtered.push(s);
                    }
                    makeASTWithMeta(EBlock(filtered), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

