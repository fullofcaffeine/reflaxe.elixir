package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StatementBlockFlattenTransforms
 *
 * WHAT
 * - Flattens nested EBlock/EDo nodes that appear as standalone statements inside
 *   another EBlock/EDo statement list.
 *
 * WHY
 * - The compiler sometimes emits nested blocks to group sequences, but Elixir blocks
 *   are scope-transparent and the printer renders these nested blocks as a flat
 *   sequence anyway.
 * - Several hygiene/analysis passes operate "per statement list" and can miss
 *   cross-block uses when a nested block is treated as a separate list, causing
 *   incorrect underscoring or missed rewrites.
 *
 * HOW
 * - For each EBlock/EDo, splice child EBlock/EDo statements into the parent list:
 *   - parent: [a, (do [b, c]), d] → [a, b, c, d]
 * - Only flattens when the nested block is in *statement position* (an element of the list),
 *   not when a block is used as an expression argument.
 *
 * EXAMPLES
 * Before:
 *   begin
 *     a
 *     (begin b; c end)
 *     d
 *   end
 * After:
 *   begin
 *     a
 *     b
 *     c
 *     d
 *   end
 */
class StatementBlockFlattenTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var flattened = flattenStatementList(stmts);
                    flattened == stmts ? n : makeASTWithMeta(EBlock(flattened), n.metadata, n.pos);
                case EDo(statements):
                    var flattenedStatements = flattenStatementList(statements);
                    flattenedStatements == statements ? n : makeASTWithMeta(EDo(flattenedStatements), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        };
    }

    static function flattenStatementList(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length == 0) return stmts;
        var out: Array<ElixirAST> = [];
        var changed = false;

        for (s in stmts) {
            var unwrapped = unwrapParen(s);
            switch (unwrapped.def) {
                case EBlock(inner):
                    changed = true;
                    for (it in inner) out.push(it);
                case EDo(innerStatements):
                    changed = true;
                    for (statement in innerStatements) out.push(statement);
                default:
                    out.push(s);
            }
        }

        return changed ? out : stmts;
    }
}

#end
