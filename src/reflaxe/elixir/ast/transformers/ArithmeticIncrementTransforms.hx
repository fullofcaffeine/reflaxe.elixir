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
 * - Converts standalone arithmetic increments/decrements used as statements into
 *   explicit assignments (count = count + 1), and drops bare numeric literals
 *   (1/0/0.0) used as statements anywhere in blocks or function bodies.
 *
 * WHY
 * - Prevents warnings from unused numeric expressions and ensures mutation intent
 *   is explicit and idiomatic in generated Elixir.
 *
 * HOW
 * - In EBlock/EDo bodies, for each statement:
 *   - If EBinary(Add|Subtract, EVar(v), EInteger(1|…)) → EMatch(PVar(v), EBinary(...))
 *   - Drop EInteger(1|0) and EFloat(0.0)
 * - Apply the same normalization to EFn clause bodies when they are blocks.
 */
class ArithmeticIncrementTransforms {
    static function rewriteStmt(stmt: ElixirAST): Null<ElixirAST> {
        return switch (stmt.def) {
            case EBinary(op, left, right):
                switch (op) {
                    case Add | Subtract:
                        switch [left.def, right.def] {
                            case [EVar(v), EInteger(_) | EFloat(_)]:
                                makeAST(EMatch(PVar(v), makeAST(EBinary(op, left, right))));
                            case [EInteger(_) | EFloat(_), EVar(v)]:
                                makeAST(EMatch(PVar(v), makeAST(EBinary(op, left, right))));
                            default:
                                null;
                        }
                    default: null;
                }
            case EInteger(v) if (v == 1 || v == 0):
                // drop
                makeAST(ENil);
            case EFloat(f) if (f == 0.0):
                makeAST(ENil);
            default:
                null;
        }
    }

    static function normalizeBlock(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        for (s in stmts) {
            var r = rewriteStmt(s);
            if (r == null) {
                // keep original
                out.push(s);
            } else if (r.def != ENil) {
                out.push(r);
            } else {
                // dropped literal -> skip
            }
        }
        return out;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    makeASTWithMeta(EBlock(normalizeBlock(stmts)), n.metadata, n.pos);
                case EDo(stmts):
                    makeASTWithMeta(EDo(normalizeBlock(stmts)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        switch (b.def) {
                            case EBlock(stmts):
                                newClauses.push({ args: cl.args, guard: cl.guard, body: makeASTWithMeta(EBlock(normalizeBlock(stmts)), b.metadata, b.pos) });
                            case EDo(stmts):
                                newClauses.push({ args: cl.args, guard: cl.guard, body: makeASTWithMeta(EDo(normalizeBlock(stmts)), b.metadata, b.pos) });
                            default:
                                newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

