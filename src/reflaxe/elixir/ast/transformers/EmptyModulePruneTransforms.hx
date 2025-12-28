package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EmptyModulePruneTransforms
 *
 * WHAT
 * - Drops defmodule nodes whose body is completely empty (no functions, no
 *   attributes), as these arise when DCE removes all members.
 *
 * WHY
 * - Avoids emitting noisy empty modules like `defmodule ChangesetUtils do end`.
 *   These offer no runtime value and clutter the output.
 *
 * HOW
 * - Matches `EDefmodule(name, EBlock([]))` and prunes it by returning an empty
 *   block (caller context will naturally drop it from parent EBlock).
 * - Conservatively keeps modules that contain any statements (aliases, docs,
 *   attributes, defs, uses, imports, requires).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EmptyModulePruneTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefmodule(_name, doBlock):
                    switch (doBlock.def) {
                        case EBlock(stmts) if (stmts.length == 0):
                            // prune module by returning an empty block at this level
                            makeASTWithMeta(EBlock([]), n.metadata, n.pos);
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

