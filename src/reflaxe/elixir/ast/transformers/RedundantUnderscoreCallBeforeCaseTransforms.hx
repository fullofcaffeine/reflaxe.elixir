package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * RedundantUnderscoreCallBeforeCaseTransforms
 *
 * WHAT
 * - Removes underscore-only remote call assignments that immediately precede a
 *   `case` on the same remote call. Example:
 *     _ = Repo.delete(todo)
 *     case Repo.delete(todo) do ... end
 *   →
 *     case Repo.delete(todo) do ... end
 *
 * WHY
 * - The first call has no effect (its result is discarded) and duplicates the
 *   side-effecting operation, causing errors like stale deletes/updates.
 *
 * HOW
 * - For each EBlock, scan adjacent statement pairs. If a statement is an
 *   underscore assignment to a remote call and the next statement is a case on
 *   an identical remote call (module, function, and argument list match by
 *   AST print equality), drop the underscore assignment.
 */
class RedundantUnderscoreCallBeforeCaseTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var dropCurrent = false;
                        if (i + 1 < stmts.length) {
                            var s1 = stmts[i];
                            var s2 = stmts[i + 1];
                            var s1IsUnderscoreAssignToCall = false;
                            var s1Call: Null<ElixirAST> = null;
                            switch (s1.def) {
                                case EMatch(pat, rhs):
                                    switch (pat) { case PVar(nm) if (nm == "_"): s1IsUnderscoreAssignToCall = isRemoteCall(rhs); s1Call = rhs; default: }
                                case EBinary(Match, left, rhs2):
                                    // Handle direct underscore lhs: _ = call
                                    switch (left.def) { case EVar(nm2) if (nm2 == "_"): s1IsUnderscoreAssignToCall = isRemoteCall(rhs2); s1Call = rhs2; default: }
                                    // Handle chained matches: var = _ = call
                                    if (!s1IsUnderscoreAssignToCall) {
                                        var rhsMost = rightmost(rhs2);
                                        var hasUnderscore = matchChainHasUnderscoreBinder(rhs2);
                                        if (hasUnderscore && isRemoteCall(rhsMost)) { s1IsUnderscoreAssignToCall = true; s1Call = rhsMost; }
                                    }
                                default:
                            }
                            if (s1IsUnderscoreAssignToCall && s1Call != null) {
                                // Check s2 is case on same call
                                switch (s2.def) {
                                    case ECase(expr, _):
                                        var ex = expr;
                                        // unwrap parentheses in scrutinee
                                        ex = switch (ex.def) { case EParen(inner): inner; default: ex; }
                                        if (callsEqual(s1Call, ex)) {
                                            dropCurrent = true;
                                        }
                                    default:
                                }
                            }
                        }
                        if (dropCurrent) {
                            // Skip s1, only push s2 (handled in next loop step)
                            i++;
                            continue;
                        }
                        out.push(stmts[i]);
                        i++;
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isRemoteCall(e: ElixirAST): Bool {
        return switch (e.def) { case ERemoteCall(_, _, _): true; default: false; }
    }

    static function rightmost(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EBinary(Match, _, r): rightmost(r);
            case EMatch(_, r2): rightmost(r2);
            case EParen(inner): rightmost(inner);
            default: e;
        }
    }

    static function matchChainHasUnderscoreBinder(e: ElixirAST): Bool {
        return switch (e.def) {
            case EBinary(Match, l, r):
                var hasLeft = switch (l.def) { case EVar(nm) if (nm == "_"): true; default: false; };
                hasLeft || matchChainHasUnderscoreBinder(r);
            case EMatch(pat, r2):
                var has = switch (pat) { case PVar(nm) if (nm == "_"): true; default: false; };
                has || matchChainHasUnderscoreBinder(r2);
            case EParen(inner): matchChainHasUnderscoreBinder(inner);
            default: false;
        }
    }

    static function callsEqual(a: ElixirAST, b: ElixirAST): Bool {
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
            default:
                false;
        }
    }
}

#end
