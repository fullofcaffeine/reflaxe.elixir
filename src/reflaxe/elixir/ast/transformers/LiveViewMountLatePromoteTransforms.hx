package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * LiveViewMountLatePromoteTransforms
 *
 * WHAT
 * - Late safety net: promotes the third parameter of LiveView mount/3 from an
 *   underscored name (e.g., _socket) to `socket` and rewrites body references.
 *
 * WHY
 * - Earlier passes may miss certain shapes or later underscore passes may reintroduce
 *   an underscored name. This ensures final emitted code adheres to LiveView idiom
 *   and avoids warnings like "underscored variable _socket is used after being set".
 *
 * HOW
 * - Runs late in the pipeline. For any def/defp named `mount` with >= 3 params, if
 *   the 3rd param is PVar starting with an underscore, rename to `socket` and rewrite
 *   all EVar occurrences of the old name in the body.
 */
class LiveViewMountLatePromoteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body) if (name == "mount" && params != null && params.length >= 3):
                    promoteAt(n, false);
                case EDefp(name, params, guards, body) if (name == "mount" && params != null && params.length >= 3):
                    promoteAt(n, true);
                default:
                    n;
            }
        });
    }

    static function promoteAt(n: ElixirAST, isPrivate: Bool): ElixirAST {
        var params: Array<EPattern> = switch (n.def) {
            case EDef(_, ps, _, _): ps;
            case EDefp(_, ps, _, _): ps;
            default: null;
        }
        if (params == null || params.length < 3) return n;
        var third = params[2];
        switch (third) {
            // Promote when the third param is any var not named `socket` (covers underscored and mismatched names)
            case PVar(pname) if (pname != null && pname != "socket"):
                var newParams = params.copy();
                newParams[2] = PVar("socket");
                var newBody = renameVarInBody(getBody(n), pname, "socket");
                return makeASTWithMeta(isPrivate ? EDefp("mount", newParams, getGuards(n), newBody) : EDef("mount", newParams, getGuards(n), newBody), n.metadata, n.pos);
            default:
                return n;
        }
    }

    static function getBody(n: ElixirAST): ElixirAST {
        return switch (n.def) {
            case EDef(_, _, _, b): b;
            case EDefp(_, _, _, b): b;
            default: n;
        }
    }
    static function getGuards(n: ElixirAST): Null<ElixirAST> {
        return switch (n.def) {
            case EDef(_, _, g, _): g;
            case EDefp(_, _, g, _): g;
            default: null;
        }
    }

    static function renameVarInBody(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end
