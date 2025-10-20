package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveViewMountSocketParamPromoteTransforms
 *
 * WHAT
 * - Promotes the third parameter of LiveView mount/3 from an underscored or
 *   non-standard binder to the idiomatic `socket` name and rewrites body
 *   references accordingly.
 *
 * WHY
 * - Phoenix LiveView mount/3 conventions use `socket` as the third argument.
 *   Downstream passes and shape-based rewrites (e.g., assign/2 normalization)
 *   expect a declared `socket` binder. Leaving `_socket` or other names can
 *   cause fallback heuristics to pick the wrong parameter, producing
 *   unidiomatic or incorrect code.
 *
 * HOW
 * - Targets any function named `mount` with at least 3 parameters.
 * - If the third parameter is `PVar(name)` and `name != "socket"`, rename it
 *   to `socket` and rewrite body occurrences of the old name to `socket`.
 * - Skips when the third parameter is already `socket` or a wildcard.
 * - Shape-based; no app-specific heuristics.
 *
 * EXAMPLES
 * Before:
 *   def mount(params, _session, _socket) do
 *     {:ok, Phoenix.Component.assign(socket, assigns)}
 *   end
 * After:
 *   def mount(params, _session, socket) do
 *     {:ok, Phoenix.Component.assign(socket, assigns)}
 *   end
 */
class LiveViewMountSocketParamPromoteTransforms {
    public static function promotePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body) if (name == "mount" && params != null && params.length >= 3):
                    var third = params[2];
                    switch (third) {
                        case PVar(pname) if (pname != null && pname != "socket"):
                            var newParams = params.copy();
                            newParams[2] = PVar("socket");
                            var newBody = renameVarInBody(body, pname, "socket");
                            makeASTWithMeta(EDef(name, newParams, guards, newBody), n.metadata, n.pos);
                        default:
                            n;
                    }
                case EDefp(privateName, privateParams, privateGuards, privateBody) if (privateName == "mount" && privateParams != null && privateParams.length >= 3):
                    var thirdParam = privateParams[2];
                    switch (thirdParam) {
                        case PVar(paramName) if (paramName != null && paramName != "socket"):
                            var updatedParams = privateParams.copy();
                            updatedParams[2] = PVar("socket");
                            var updatedBody = renameVarInBody(privateBody, paramName, "socket");
                            makeASTWithMeta(EDefp(privateName, updatedParams, privateGuards, updatedBody), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function renameVarInBody(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from):
                    makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default:
                    x;
            };
        });
    }
}

#end
