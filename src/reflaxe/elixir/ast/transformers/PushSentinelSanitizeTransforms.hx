package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PushSentinelSanitizeTransforms
 *
 * WHAT
 * - Replaces leftover `push(...)` sentinel calls with `nil` when they appear
 *   outside canonical reduce-to-comprehension rewrite contexts.
 *
 * WHY
 * - Earlier lowerings can surface `push(...)` in statement position (e.g., inside
 *   Enum.each bodies or nested IIFEs) which is invalid Elixir and not meaningful
 *   at runtime. These should either be rewritten to acc-concats (handled in
 *   ReduceBodySanitize for reduce) or eliminated as no-ops.
 *
 * HOW
 * - Walks the AST and rewrites `ECall(null, "push", _ )` to `nil` for any remaining
 *   occurrences. This is a safe no-op in statement position and yields valid syntax.
 */
class PushSentinelSanitizeTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECall(func, method, _ ) if (func == null && method == "push"):
                    makeAST(ENil);
                default:
                    n;
            }
        });
    }
}

#end

