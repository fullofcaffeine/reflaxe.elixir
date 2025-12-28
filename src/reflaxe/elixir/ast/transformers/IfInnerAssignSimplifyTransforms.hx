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

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class IfInnerAssignSimplifyTransforms {
    static inline function isVarName(node:ElixirAST, name:String):Bool {
        return node != null && node.def != null && switch (node.def) {
            case EVar(v): v == name;
            case EParen(inner): isVarName(inner, name);
            default: false;
        };
    }

    static inline function extractAssignedRhsToVar(node:ElixirAST, lhs:String):Null<ElixirAST> {
        if (node == null || node.def == null) return null;
        return switch (node.def) {
            case EMatch(pat, inner) if (isSameVar(pat, lhs)): inner;
            case EBinary(Match, left, inner):
                switch (left.def) {
                    case EVar(name) if (name == lhs): inner;
                    default: null;
                }
            default:
                null;
        };
    }

    static inline function simplifyBranch(lhs:String, branch:ElixirAST):ElixirAST {
        if (branch == null || branch.def == null) return branch;
        return switch (branch.def) {
            case EMatch(pat, inner) if (isSameVar(pat, lhs)):
                inner; // drop inner reassign
            case EBinary(Match, left, inner):
                switch (left.def) {
                    case EVar(name) if (name == lhs): inner; // drop inner reassign
                    default: branch;
                }
            case EBlock(stmts) if (stmts.length >= 2):
                // Common shape: <prefix...>; lhs = expr; lhs
                var last = stmts[stmts.length - 1];
                var prior = stmts[stmts.length - 2];
                var rhs = extractAssignedRhsToVar(prior, lhs);
                if (rhs != null && isVarName(last, lhs)) {
                    var prefix = stmts.slice(0, stmts.length - 2);
                    makeASTWithMeta(EBlock(prefix.concat([rhs])), branch.metadata, branch.pos);
                } else {
	                    // Legacy behavior: if the *last* statement is a rebind, replace it with RHS.
	                    var replacement:Null<ElixirAST> = extractAssignedRhsToVar(last, lhs);
	                    if (replacement != null) {
	                        var prefixStatements = stmts.slice(0, stmts.length - 1);
	                        makeASTWithMeta(EBlock(prefixStatements.concat([replacement])), branch.metadata, branch.pos);
	                    } else {
	                        branch;
	                    }
	                }
            default:
                branch;
        };
    }

    static inline function simplifyIfForVar(lhs:String, node:ElixirAST):ElixirAST {
        if (node == null || node.def == null) return node;
        return switch (node.def) {
            case EIf(cond, thenExpr, elseExpr):
                var newThen = simplifyBranch(lhs, thenExpr);
                var newElse = elseExpr != null ? simplifyBranch(lhs, elseExpr) : elseExpr;
                makeASTWithMeta(EIf(cond, newThen, newElse), node.metadata, node.pos);
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
                case EBinary(Match, left, rhsExpr):
                    switch (left.def) {
                        case EVar(lhsName):
                            var simplifiedRhs = simplifyIfForVar(lhsName, rhsExpr);
                            if (simplifiedRhs != rhsExpr) makeASTWithMeta(EBinary(Match, left, simplifiedRhs), n.metadata, n.pos) else n;
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
