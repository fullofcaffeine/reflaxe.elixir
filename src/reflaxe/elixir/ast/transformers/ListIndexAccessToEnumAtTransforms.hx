package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListIndexAccessToEnumAtTransforms
 *
 * WHAT
 * - Rewrites numeric index access on known list fields to Enum.at/2.
 *   Example: entry.metas[0] -> Enum.at(entry.metas, 0)
 *
 * WHY
 * - Elixir's Access protocol does not support indexing lists by number with []
 *   (it raises). Haxe-style array indexing lowers to EAccess; we must emit
 *   Enum.at(list, index) for list values.
 *
 * HOW
 * - Targeted, safe rewrite: if we see EAccess(EField(_, "metas"), EInteger(_)),
 *   rewrite to Enum.at(fieldExpr, index). This covers Phoenix Presence entries
 *   (entry.metas) without risking map integer-key access.
 */
class ListIndexAccessToEnumAtTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EAccess(target, key):
                    switch [target.def, key.def] {
                        case [EField(obj, field), EInteger(_)] if (field == 'metas'):
                            var fieldExpr = makeAST(EField(obj, field));
                            makeASTWithMeta(ERemoteCall(makeAST(EVar('Enum')), 'at', [fieldExpr, key]), n.metadata, n.pos);
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

