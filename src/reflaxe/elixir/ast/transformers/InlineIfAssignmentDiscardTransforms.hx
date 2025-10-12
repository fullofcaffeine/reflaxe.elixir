package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineIfAssignmentDiscardTransforms
 *
 * WHAT
 * - Rewrite inline if branches of the form `if cond, do: var = expr` to
 *   `if cond, do: _ = expr` to avoid unused variable warnings when rebinding
 *   locals in expression context (common in LiveView helper lowers).
 *
 * WHY
 * - In Elixir, rebinding a captured variable inside a closure or inline branch
 *   does not mutate the outer binding and triggers warnings-as-errors when the
 *   branch assignment is considered an unused rebind.
 *
 * HOW
 * - Visit all EIf nodes and, when thenBranch is an assignment to a plain EVar,
 *   replace the LHS with a wildcard pattern.
 */
class InlineIfAssignmentDiscardTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBr, elseBr):
                    var newThen = thenBr;
                    switch (thenBr.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) { case EVar(_): newThen = makeASTWithMeta(EMatch(PWildcard, rhs), thenBr.metadata, thenBr.pos); default: }
                        case EMatch(pat, rhs2):
                            switch (pat) { case PVar(_): newThen = makeASTWithMeta(EMatch(PWildcard, rhs2), thenBr.metadata, thenBr.pos); default: }
                        default:
                    }
                    makeASTWithMeta(EIf(cond, newThen, elseBr), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
