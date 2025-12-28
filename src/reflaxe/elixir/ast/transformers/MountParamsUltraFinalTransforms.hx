package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountParamsUltraFinalTransforms
 *
 * WHAT
 * - Absolute-final enforcement for Phoenix LiveView mount/3: ensure the first
 *   parameter name is `params` when declared as a PVar, and rewrite body
 *   references from the previous binder (e.g., `_params`) to `params`.
 *
 * WHY
 * - Prevents warnings from underscored binders that are used in the body and
 *   guarantees idiomatic naming independent of earlier hygiene decisions.
 *
 * HOW
 * - Match `def mount/3` with first arg PVar not equal to `params`, rename to
 *   `params` and rewrite body EVar occurrences.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class MountParamsUltraFinalTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length == 3):
                    switch (args[0]) {
                        case PVar(pn) if (pn != null && pn != "params"):
                            var old = pn;
                            var newArgs = args.copy();
                            newArgs[0] = PVar("params");
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

