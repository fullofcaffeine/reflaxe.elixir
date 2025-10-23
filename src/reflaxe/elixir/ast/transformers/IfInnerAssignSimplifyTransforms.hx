package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfInnerAssignSimplifyTransforms
 *
 * WHAT
 * - Simplify redundant inner reassignments in `if` expressions of the form:
 *   lhs = if cond do lhs = expr else lhs end
 *   → lhs = if cond do expr else lhs end
 *
 * WHY
 * - The inner `lhs =` can trigger variable shadow warnings in macro-heavy code paths
 *   (e.g., Ecto.Query macros). Removing the inner rebind yields cleaner, idiomatic Elixir
 *   without changing semantics.
 *
 * HOW
 * - Transform EMatch(PVar(lhs), EIf(cond, thenExpr, elseExpr)) where thenExpr is
 *   EMatch(PVar(lhs), inner). Replace thenExpr with `inner`.
 * - shape-based only; no name heuristics; applies to any variable name.
 */
class IfInnerAssignSimplifyTransforms {
    static inline function simplifyIfForVar(lhs:String, node:ElixirAST):ElixirAST {
        if (node == null || node.def == null) return node;
        return switch (node.def) {
            case EIf(cond, thenExpr, elseExpr):
                var newThen = switch (thenExpr.def) {
                    case EMatch(pat, inner) if (isSameVar(pat, lhs)):
                        inner; // drop inner reassign
                    case EBinary(Match, left, inner):
                        switch (left.def) {
                            case EVar(name) if (name == lhs): inner; // drop inner reassign
                            default: thenExpr;
                        }
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
                        } else {
                            thenExpr;
                        }
                    default:
                        thenExpr;
                };
                makeASTWithMeta(EIf(cond, newThen, elseExpr), node.metadata, node.pos);
            default:
                node;
        }
    }

    static inline function isSameVar(pat:ElixirAST.EPattern, lhs:String):Bool {
        return switch (pat) {
            case PVar(name): name == lhs;
            default: false;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Match on simple variable assignment
                case EMatch(pattern, rhs):
                    switch (pattern) {
                        case PVar(lhs):
                            var simplified = simplifyIfForVar(lhs, rhs);
                            if (simplified != rhs) makeASTWithMeta(EMatch(pattern, simplified), n.metadata, n.pos) else n;
                        default:
                            n;
                    }
                // Also handle binary match form: left = rhs
                case EBinary(Match, left, rhs2):
                    switch (left.def) {
                        case EVar(lhs2):
                            var simplified2 = simplifyIfForVar(lhs2, rhs2);
                            if (simplified2 != rhs2) makeASTWithMeta(EBinary(Match, left, simplified2), n.metadata, n.pos) else n;
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
