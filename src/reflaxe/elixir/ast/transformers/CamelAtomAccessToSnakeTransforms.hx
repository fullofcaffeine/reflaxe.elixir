package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.NameUtils;

/**
 * CamelAtomAccessToSnakeTransforms
 *
 * WHAT
 * - Rewrites EAccess(target, :camelCase) to EAccess(target, :snake_case).
 *
 * WHY
 * - Ecto schemas and idiomatic Elixir structs use snake_case field atoms.
 *   If any builder path emits camelCase atoms for struct/map access, it
 *   leads to KeyError at runtime (e.g., key :dueDate not found).
 *
 * HOW
 * - Transform EAccess where the key is EAtom and NameUtils.toSnakeCase(key)
 *   differs from the original. Replace with the snake_case atom. Conservative,
 *   shape-based; does not depend on variable names or app-specific modules.
 */
class CamelAtomAccessToSnakeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EAccess(target, {def: EAtom(a)}):
                    var snake = NameUtils.toSnakeCase(a);
                    if (snake != a) makeASTWithMeta(EAccess(target, makeAST(EAtom(snake))), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }
}

#end

