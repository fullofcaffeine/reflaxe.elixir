package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveNoreplyAtomFixTransforms
 *
 * WHAT
 * - Normalizes `{:no_reply, socket}` to `{:noreply, socket}` in LiveView-style
 *   return tuples (and in general tuple first element).
 *
 * WHY
 * - Phoenix expects the atom `:noreply`. Using `:no_reply` crashes at runtime.
 *   This transform fixes the common misspelling without app coupling.
 *
 * HOW
 * - Traverse the AST and rewrite ETuple whose first element is the atom `no_reply`
 *   to the atom `noreply`.
 */
class LiveNoreplyAtomFixTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ETuple(items) if (items != null && items.length >= 1):
                    var first = items[0];
                    switch (first.def) {
                        case EAtom(atom) if (atom == "no_reply"):
                            var newItems = items.copy();
                            newItems[0] = makeAST(EAtom("noreply"));
                            makeASTWithMeta(ETuple(newItems), n.metadata, n.pos);
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

