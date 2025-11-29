package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * IfThenDoToBlockTransforms
 *
 * WHAT
 * - Normalizes any `if condition do <EDo ...> else ... end` shape by converting the
 *   then-branch from EDo to EBlock. This prevents the Elixir printer from emitting
 *   `if ... do do ... end` (nested do/end), which is invalid syntax.
 *
 * WHY
 * - Some expression-lowering paths can introduce an EDo node inside the then-branch
 *   of an EIf. The printer already emits the surrounding `do ... end` for the `if`,
 *   so an inner EDo causes a duplicated `do` token.
 *
 * HOW
 * - Walk the AST and rewrite EIf nodes: when `thenBranch` is EDo([...]) emit
 *   `EIf(cond, EBlock([...]), elseBranch)`. Non-destructive for else-branch.
 */
class IfThenDoToBlockTransforms {
    public static function normalizePass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBr, elseBr) if (thenBr != null && thenBr.def != null):
                    switch (thenBr.def) {
                        case EDo(inner) if (inner != null):
                            makeASTWithMeta(EIf(cond, makeASTWithMeta(EBlock(inner), thenBr.metadata, thenBr.pos), elseBr), n.metadata, n.pos);
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
