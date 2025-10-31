package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsUltraFinalTransforms
 *
 * WHAT
 * - Absolute-final safeguard that enforces the second parameter name of
 *   Phoenix LiveView handle_event/3 to be `params` when declared as a
 *   plain variable (PVar). It also rewrites body references from the old
 *   underscored name to `params`.
 *
 * WHY
 * - Earlier promotion passes may miss certain wrapper shapes or be undone
 *   by late underscore hygiene. Elixir warns when an underscored parameter
 *   like `_params` is used. This pass guarantees idiomatic naming at the
 *   end of the pipeline without coupling to any application specifics.
 *
 * HOW
 * - Find any `def handle_event/3` whose second arg is PVar and not
 *   exactly `params`. If it begins with `_`, strip the underscore; in any
 *   case, rename the binder to `params` and rewrite body EVar occurrences
 *   of the old name to `params`.
 *
 * EXAMPLES
 *   Before:
 *     def handle_event("create_todo", _params, socket) do
 *       {:noreply, create_todo_typed(_params, socket)}
 *     end
 *   After:
 *     def handle_event("create_todo", params, socket) do
 *       {:noreply, create_todo_typed(params, socket)}
 *     end
 */
class HandleEventParamsUltraFinalTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
                    switch (args[1]) {
                        case PVar(pn) if (pn != null && pn != "params"):
                            var old = pn;
                            var newArgs = args.copy();
                            newArgs[1] = PVar("params");
                            var newBody = renameVar(body, old, "params");
                            makeASTWithMeta(EDef(name, newArgs, guards, newBody), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function renameVar(body: ElixirAST, from:String, to:String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end

