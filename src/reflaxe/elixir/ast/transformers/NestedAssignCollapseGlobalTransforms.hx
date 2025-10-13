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
 */
class NestedAssignCollapseGlobalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Match, left, rhs):
                    switch (rhs.def) {
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
