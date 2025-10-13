package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - In block-like contexts (EBlock/EDo/EFn bodies), underscore local assignment targets
 *   when they are not referenced later in the same block. Also handles nested assignments
 *   inside `outer = (inner = expr)` by underscoring `inner` when unused.
 *
 * WHY
 * - Removes warnings for throwaway temps (e.g., g, g3) created by intermediate rewrites.
 */
/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - Late hygiene sweep that underscores local assignment targets not referenced later
 *   and collapses nested chains `outer = (inner = expr)` where safe.
 *
 * WHY
 * - Eliminates throwaway temps (g/g3/thisN) produced by intermediate rewrites that
 *   otherwise cause WAE. Collapsing nested chains produces cleaner, idiomatic code.
 *
 * HOW
 * - For EBlock/EDo/EFn bodies, scan each statement, detect nested matches, and either
 *   collapse or underscore unused binders. Variable usage checks look through common
 *   constructs to avoid false positives/negatives.
 */
class LocalAssignUnderscoreLateTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock(processStmts(stmts)), n.metadata, n.pos);
                case EDo(stmts2): makeASTWithMeta(EDo(processStmts(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(processStmts(ss)), b.metadata, b.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(processStmts(ss2)), b.metadata, b.pos);
                            default: b;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * processStmts
     *
     * WHAT
     * - Processes a statement list, applying nested assign collapse and underscore
     *   of unused local assignment targets.
     */
    static function processStmts(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case EBinary(Match, left, rhs):
                    // Nested: outer = (inner = expr) → underscore inner if unused later
                    var collapse = false;
                    var collapsedExpr:Null<ElixirAST> = null;
                    var newRhs = switch (rhs.def) {
                        case EBinary(Match, leftInner, expr):
                            var innerName:Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                            if (innerName != null && !VarUseAnalyzer.usedLater(stmts, i + 1, innerName)) {
                                // Collapse nested: outer = (inner = expr) -> outer = expr
                                collapse = true;
                                collapsedExpr = expr;
                                rhs;
                            } else rhs;
                        default: rhs;
                    };
                    // Left var unused later → underscore
                    var leftName:Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                    var newLeft = left;
                    if (leftName != null && !VarUseAnalyzer.usedLater(stmts, i + 1, leftName)) {
                        newLeft = makeASTWithMeta(EVar('_' + leftName), left.metadata, left.pos);
                    }
                    if (collapse && collapsedExpr != null) {
                        #if debug_hygiene
                        Sys.println('[LocalAssignUnderscoreLate] collapsing nested assign into outer');
                        #end
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, collapsedExpr), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, newRhs), s.metadata, s.pos));
                    }
                case EMatch(pat, rhs):
                    var collapse2 = false;
                    var collapsedExpr2:Null<ElixirAST> = null;
                    var newRhs2 = switch (rhs.def) {
                        case EBinary(Match, leftInner2, expr2):
                            var innerName2:Null<String> = switch (leftInner2.def) { case EVar(n): n; default: null; };
                            if (innerName2 != null && !VarUseAnalyzer.usedLater(stmts, i + 1, innerName2)) {
                                collapse2 = true; collapsedExpr2 = expr2; rhs;
                            } else rhs;
                        case EMatch(patInner2, expr3):
                            var innerName3:Null<String> = switch (patInner2) { case PVar(n3): n3; default: null; };
                            if (innerName3 != null && !VarUseAnalyzer.usedLater(stmts, i + 1, innerName3)) {
                                collapse2 = true; collapsedExpr2 = expr3; rhs;
                            } else rhs;
                        default: rhs;
                    };
                    var leftName2:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                    var newPat = pat;
                    if (leftName2 != null && !VarUseAnalyzer.usedLater(stmts, i + 1, leftName2) && leftName2.charAt(0) != '_') {
                        newPat = PVar('_' + leftName2);
                    }
                    if (collapse2 && collapsedExpr2 != null) {
                        out.push(makeASTWithMeta(EMatch(newPat, collapsedExpr2), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EMatch(newPat, newRhs2), s.metadata, s.pos));
                    }
                default:
                    out.push(s);
            }
        }
        return out;
    }

    // usage analysis delegated to VarUseAnalyzer
}

#end
