package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnNumericSentinelCleanupTransforms
 *
 * WHAT
 * - Remove standalone numeric sentinel literals (0, 1, 0.0) from EFn clause bodies.
 *
 * WHY
 * - Loop-lowering leaves numeric sentinels inside anonymous function bodies. They cause
 *   warnings and have no semantic effect.
 *
 * HOW
 * - For each anonymous function (EFn) clause body, filter EBlock/EDo statements and
 *   drop bare EInteger(0|1) and EFloat(0.0) statements.
 *
 * EXAMPLES
 * Haxe:
 *   arr.each(function(x) {
 *     1; // sentinel
 *     doWork(x);
 *   });
 * Elixir (before):
 *   Enum.each(arr, fn x -> 1; do_work(x) end)
 * Elixir (after):
 *   Enum.each(arr, fn x -> do_work(x) end)
 */
class EFnNumericSentinelCleanupTransforms {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var body = cl.body;
                        var newBody = switch (body.def) {
                            case EBlock(stmts):
                                var out = [];
                                for (s in stmts) switch (s.def) {
                                    case EInteger(v) if (v == 0 || v == 1):
                                    case EFloat(f) if (f == 0.0):
                                    default: out.push(s);
                                }
                                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
                            case EDo(stmts2):
                                var out2 = [];
                                for (s2 in stmts2) switch (s2.def) {
                                    case EInteger(v2) if (v2 == 0 || v2 == 1):
                                    case EFloat(f2) if (f2 == 0.0):
                                    default: out2.push(s2);
                                }
                                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
                            default:
                                body;
                        };
                        newClauses.push({args: cl.args, guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
