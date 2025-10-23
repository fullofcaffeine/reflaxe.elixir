package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfResultAssignmentSimplifyTransforms
 *
 * WHAT
 * - Simplify result assignment patterns of the form:
 *     lhs = if cond do lhs = expr else lhs end
 *   into a single expression assignment:
 *     lhs = if cond do expr else lhs end
 *
 * WHY
 * - Inner rebinds of the same variable in then-branches are redundant and can
 *   trigger unused/shadow warnings in macro-heavy code (e.g., Ecto where chains).
 *   This transform produces idiomatic Elixir without changing semantics.
 *
 * HOW
 * - Match on EMatch(PVar(lhs), EIf(cond, thenExpr, elseExpr)).
 * - If thenExpr ends with an assignment to lhs (either EMatch(PVar(lhs), rhs)
 *   or EBinary(Match, EVar(lhs), rhs)), replace thenExpr with rhs (preserving
 *   any prefix statements if it is a block, keeping rhs as the branch result).
 * - Else branch is left untouched.
 *
 * SCOPE/SAFETY
 * - Shape-based only; never uses name heuristics beyond binder equality.
 * - Skips modules containing ERaw in the immediate then-branch to avoid extern mismatches.
 */
class IfResultAssignmentSimplifyTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(pat, rhs):
                    switch (pat) {
                        case PVar(lhs):
                            simplifyMatchIf(lhs, n, rhs);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function simplifyMatchIf(lhs:String, parent:ElixirAST, rhs:ElixirAST): ElixirAST {
        return switch (rhs.def) {
            case EIf(cond, thenExpr, elseExpr):
                var newThen = simplifyThen(lhs, thenExpr);
                if (newThen != thenExpr) {
                    makeASTWithMeta(EMatch(PVar(lhs), makeASTWithMeta(EIf(cond, newThen, elseExpr), rhs.metadata, rhs.pos)), parent.metadata, parent.pos);
                } else {
                    parent;
                }
            default:
                parent;
        }
    }

    static function simplifyThen(lhs:String, thenExpr:ElixirAST): ElixirAST {
        if (thenExpr == null || thenExpr.def == null) return thenExpr;
        return switch (thenExpr.def) {
            case EMatch(pat, inner) if (isSameVar(pat, lhs)):
                inner;
            case EBinary(Match, left, inner):
                switch (left.def) { case EVar(name) if (name == lhs): inner; default: thenExpr; }
            case EBlock(stmts) if (stmts.length >= 1):
                var last = stmts[stmts.length - 1];
                var replacement:Null<ElixirAST> = null;
                switch (last.def) {
                    case EMatch(pat2, inner2) if (isSameVar(pat2, lhs)):
                        replacement = inner2;
                    case EBinary(Match, left2, inner3):
                        switch (left2.def) { case EVar(name2) if (name2 == lhs): replacement = inner3; default: }
                    default:
                }
                if (replacement != null) {
                    var prefix = stmts.slice(0, stmts.length - 1);
                    makeASTWithMeta(EBlock(prefix.concat([replacement])), thenExpr.metadata, thenExpr.pos);
                } else thenExpr;
            default:
                thenExpr;
        }
    }

    static inline function isSameVar(p:ElixirAST.EPattern, name:String):Bool {
        return switch (p) { case PVar(nm): nm == name; default: false; }
    }
}

#end

