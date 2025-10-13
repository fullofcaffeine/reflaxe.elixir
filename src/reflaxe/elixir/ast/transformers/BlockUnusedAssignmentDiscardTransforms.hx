package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In function bodies (EDef → EBlock), rewrite `var = expr` to `_ = expr` when `var` is not
 *   referenced later in the same block.
 */
/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In block-like contexts (EDef/EFn/EBlock/EDo), rewrite `var = expr` to `_ = expr`
 *   when `var` is not referenced later in the same block. Also supports `EMatch(PVar, rhs)`.
 *
 * WHY
 * - Removes throwaway temps introduced by lowerings without changing semantics. This
 *   reduces warnings and enables WAE=0 for generated LiveView helpers.
 *
 * HOW
 * - For each block, forward-scan for later usage (including ERaw, map/keyword, struct
 *   update targets) before deciding to discard the assignment target.
 *
 * EXAMPLES
 * Before: this1 = Ecto.Changeset.change(cs); ... (no later use of this1)
 * After:  _ = Ecto.Changeset.change(cs)
 */
class BlockUnusedAssignmentDiscardTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var nb = rewriteBody(body);
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EBlock(_):
                    rewriteBody(n);
                case EDo(_):
                    rewriteBody(n);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        newClauses.push({ args: cl.args, guard: cl.guard, body: rewriteBody(b) });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * rewriteBody
     *
     * WHAT
     * - Performs the per-block transformation, handling both EBinary(Match, …) and
     *   EMatch(PVar, rhs) forms.
     */
    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(nm):
                                    // Safety: do not discard known supervisor children binding
                                    if (nm == "children") { out.push(s); break; }
                                    if (!VarUseAnalyzer.usedLater(stmts, i + 1, nm)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        case EMatch(pat, rhs2):
                            switch (pat) {
                                case PVar(nm2):
                                    if (nm2 == "children") { out.push(s); break; }
                                    if (!VarUseAnalyzer.usedLater(stmts, i + 1, nm2)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                // Treat EDo like EBlock for hygiene
                var out2:Array<ElixirAST> = [];
                for (i in 0...stmts2.length) {
                    var s2 = stmts2[i];
                    switch (s2.def) {
                        case EBinary(Match, left2, rhs2):
                            switch (left2.def) {
                                case EVar(nm2):
                                    if (!VarUseAnalyzer.usedLater(stmts2, i + 1, nm2)) {
                                        out2.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s2.metadata, s2.pos));
                                    } else out2.push(s2);
                                default: out2.push(s2);
                            }
                        default:
                            out2.push(s2);
                    }
                }
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }
}

#end
