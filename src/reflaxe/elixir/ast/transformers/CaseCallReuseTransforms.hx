package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * CaseCallReuseTransforms
 *
 * WHAT
 * - Rewrites repeated case scrutinee calls to reuse a previously-bound result within the same block.
 *   Shape before → after (structural, name-agnostic):
 *     var = Mod.func(args)
 *     case Mod.func(args) do ... end
 *   becomes:
 *     var = Mod.func(args)
 *     case var do ... end
 *
 * WHY
 * - Generated code can perform the same remote call twice (once to bind and again in a case scrutinee),
 *   which is non-idiomatic and risky if the call has side effects (Repo/DB, PubSub, etc.).
 * - Duplicated calls also interact poorly with hygiene passes, sometimes leaving unused/undefined temps.
 * - Reusing the prior result is safer, cleaner, and matches typical Elixir style.
 *
 * HOW
 * - Scope: only inside a single `EBlock([...])` (no cross-block/global analysis).
 * - Detection: for a `case <expr> do ... end`, if `<expr>` is an `ERemoteCall(Mod, func, args)`, walk
 *   backward in the same block to find a preceding `EBinary(Match, EVar(var), rhs)` where `rhs` is an
 *   identical remote call (same module, function, and argument printout). The comparison uses the
 *   ElixirASTPrinter to stringify each argument and the module node to avoid fragile name heuristics.
 * - Rewrite: replace the scrutinee expression with `EVar(var)`. Clauses and surrounding statements are
 *   left untouched; the transformation is purely a scrutinee substitution.
 *
 * EXAMPLES
 * Before:
 *   u = TodoApp.Repo.update(changeset)
 *   case TodoApp.Repo.update(changeset) do
 *     {:ok, v} -> v
 *     {:error, r} -> {:error, r}
 *   end
 * After:
 *   u = TodoApp.Repo.update(changeset)
 *   case u do
 *     {:ok, v} -> v
 *     {:error, r} -> {:error, r}
 *   end
 *
 * SAFETY & LIMITS
 * - Only applies when the module, function, and argument lists are structurally identical (printer-equal).
 * - Does not reorder or eliminate statements; if no prior matching assignment exists, the case is unchanged.
 * - No app-specific names or side-effect assumptions; strictly shape/API-based and local to the block.
 */
class CaseCallReuseTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];

                    function sameRemote(a: ElixirAST, b: ElixirAST): Bool {
                        return switch [a.def, b.def] {
                            case [ERemoteCall(modA, fA, argsA), ERemoteCall(modB, fB, argsB)]:
                                if (fA != fB) return false;
                                var modSA = ElixirASTPrinter.printAST(modA);
                                var modSB = ElixirASTPrinter.printAST(modB);
                                if (modSA != modSB) return false;
                                if (argsA.length != argsB.length) return false;
                                for (i in 0...argsA.length) {
                                    var pa = ElixirASTPrinter.printAST(argsA[i]);
                                    var pb = ElixirASTPrinter.printAST(argsB[i]);
                                    if (pa != pb) return false;
                                }
                                true;
                            default: false;
                        };
                    }

                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case ECase(expr, clauses):
                                // Search backward for a preceding assignment of the same call
                                var replaced = false;
                                var j = i - 1;
                                while (j >= 0 && !replaced) {
                                    switch (stmts[j].def) {
                                        case EBinary(Match, left, rhs) if (sameRemote(expr, rhs)):
                                            var v:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                                            if (v != null) {
                                                out.push( makeASTWithMeta(ECase(makeAST(EVar(v)), clauses), s.metadata, s.pos) );
                                                replaced = true;
                                            } else out.push(s);
                                        default:
                                            // keep scanning
                                    }
                                    j--;
                                }
                                if (!replaced) out.push(s);
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
