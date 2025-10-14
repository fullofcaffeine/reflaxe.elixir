package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StructUpdateStandaloneDiscardTransforms
 *
 * WHAT
 * - Removes standalone struct update expressions (%{struct | field: value}) that appear
 *   as non-final statements in a block, where their value is ignored.
 *
 * WHY
 * - Some immutability/struct-update transforms can introduce a bare struct update into
 *   a function body without binding or returning it, which is invalid and can refer to
 *   an undefined base (e.g., %{struct | ...}). These statements have no effect and should
 *   be discarded to avoid Elixir compile errors.
 *
 * HOW
 * - For any EBlock([...]) with more than one statement, drop any EStructUpdate nodes that
 *   are not the last statement in the block. The last statement is preserved, so legitimate
 *   “return a struct update” cases are unaffected.
 *
 * EXAMPLES
 * Before:
 *   def add_tag(todo, tag) do
 *     tags2 = if todo.tags != nil, do: todo.tags.copy(), else: []
 *     %{struct | tags2: struct.tags2 ++ [tag]}
 *     params = %{tags: tags2}
 *     changeset(todo, params)
 *   end
 * After:
 *   def add_tag(todo, tag) do
 *     tags2 = if todo.tags != nil, do: todo.tags.copy(), else: []
 *     params = %{tags: tags2}
 *     changeset(todo, params)
 *   end
 */
class StructUpdateStandaloneDiscardTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(exprs) if (exprs != null && exprs.length > 1):
                    var lastIndex = exprs.length - 1;
                    var filtered = [];
                    var i = 0;
                    while (i < exprs.length) {
                        var e = exprs[i];
                        var isStructUpdate = switch (e.def) { case EStructUpdate(_, _): true; default: false; };
                        if (i < lastIndex && isStructUpdate) {
                            // Drop non-final struct updates
                        } else {
                            filtered.push(e);
                        }
                        i++;
                    }
                    makeASTWithMeta(EBlock(filtered), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

