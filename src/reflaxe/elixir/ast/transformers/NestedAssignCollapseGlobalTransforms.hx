package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * NestedAssignCollapseGlobalTransforms
 *
 * WHAT
 * - Collapse nested chain assignments anywhere in the AST:
 *     outer = (inner = expr)  →  outer = expr
 *   and
 *     outer = (PVar(inner) = expr) → outer = expr
 *
 * WHY
 * - Eliminates throwaway temps like `g` that only serve as intermediate binders.
 *
 * HOW
 * - For binary match nodes `left = rhs`, if rhs is a nested match expression,
 *   replace with `left = expr` where `expr` is the inner RHS expression, unwrapping
 *   `EParen` one level to catch `(inner = expr)`.
 *
 * EXAMPLES
 * Haxe:
 *   var g = compute(); var x = g;
 * Elixir (before):
 *   x = (g = compute())
 * Elixir (after):
 *   x = compute()
 */
class NestedAssignCollapseGlobalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Match, left, rhs):
                    // Unwrap a single level of parentheses to catch shapes like outer = (_ = expr)
                    var r = switch (rhs.def) { case EParen(inner): inner; default: rhs; };
                    switch (r.def) {
                        case EBinary(Match, _, expr):
                            #if debug_hygiene
                            Sys.println('[NestedAssignCollapseGlobal] collapsing outer=(inner=expr)');
                            #end
                            makeASTWithMeta(EBinary(Match, left, expr), n.metadata, n.pos);
                        case EMatch(_, expr2):
                            #if debug_hygiene
                            Sys.println('[NestedAssignCollapseGlobal] collapsing outer=(PVar inner=expr)');
                            #end
                            makeASTWithMeta(EBinary(Match, left, expr2), n.metadata, n.pos);
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
