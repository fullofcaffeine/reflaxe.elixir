package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ArithmeticIncrementTransforms
 *
 * WHAT
 * - Converts standalone increment/decrement arithmetic expressions into explicit
 *   assignments, e.g., `i + 1` → `i = i + 1` when used as a statement.
 * - Also covers if-branch bodies and general block statements.
 *
 * WHY
 * - Elixir has no ++/-- operators or compound assignments; increments must be
 *   represented as rebindings. Prevents stray `count + 1` statements that have
 *   no effect and trigger warnings.
 *
 * HOW
 * - Walk blocks and condition branches. When a statement is exactly an
 *   `EBinary(Add|Subtract, EVar(name), EInteger(1))` or `...EFloat(1.0)`,
 *   rewrite to `EMatch(PVar(name), EBinary(op, EVar(name), 1))`.
 * - Conservative: only rewrite when the expression is a direct statement.
 *   Does not alter nested arithmetic inside larger expressions.
 *
 * EXAMPLES
 * Before:
 *   if cond do
 *     count + 1
 *   end
 * After:
 *   if cond do
 *     count = count + 1
 *   end
 */
class ArithmeticIncrementTransforms {
    public static function incrementToAssignmentPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (s in stmts) out.push(rewriteIncStmt(s));
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);

                case EIf(cond, thenB, elseB):
                    var newThen = rewriteIncStmt(thenB);
                    var newElse = elseB != null ? rewriteIncStmt(elseB) : null;
                    makeASTWithMeta(EIf(cond, newThen, newElse), n.metadata, n.pos);

                default:
                    n;
            }
        });
    }

    static function isOneLiteral(e: ElixirAST): Bool {
        return switch (e.def) {
            case EInteger(v): v == 1;
            case EFloat(f): f == 1.0 || f == 1;
            default: false;
        };
    }

    static function rewriteIncStmt(s: ElixirAST): ElixirAST {
        return switch (s.def) {
            case EBinary(op, {def: EVar(name)}, rhs) if ((op == Add || op == Subtract) && isOneLiteral(rhs)):
                makeASTWithMeta(EMatch(PVar(name), makeAST(EBinary(op, makeAST(EVar(name)), rhs))), s.metadata, s.pos);
            default:
                s;
        }
    }
}

#end

