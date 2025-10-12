package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceHelpersTransforms
 *
 * WHAT
 * - Normalizes helper usage around Phoenix Presence maps to avoid incorrect
 *   atom-to-string conversions when enumerating keys.
 * - Specifically rewrites `Enum.map(Map.keys(presences), &Atom.to_string/1)`
 *   to just `Map.keys(presences)` within Presence modules, since Presence keys
 *   are strings already.
 *
 * WHY
 * - Generic Reflect.fields() maps keys via Atom.to_string/1 which is only valid
 *   for atom keys. Phoenix Presence maps use string keys (e.g., user IDs). Applying
 *   Atom.to_string/1 on binaries is incorrect and can cause runtime issues.
 *
 * HOW
 * - Limit the rewrite to modules that are Presence modules by name or metadata
 *   (node.metadata.isPresence == true or module name contains "Web.Presence").
 * - Pattern-match `Enum.map(Map.keys(arg), fun)` where fun is a capture/remote call
 *   to `Atom.to_string/1`, and collapse the entire expression to `Map.keys(arg)`.
 * - Leaves all other usages untouched to avoid breaking general Reflect semantics.
 *
 * EXAMPLES
 * Before (within TodoAppWeb.Presence):
 *   Enum.map(Map.keys(all_users), &Atom.to_string/1)
 * After:
 *   Map.keys(all_users)
 */
class PresenceHelpersTransforms {
    static inline function isPresenceModuleName(name: String): Bool {
        if (name == null) return false;
        if (name.indexOf("Web.Presence") >= 0) return true;
        var suffix = ".Presence";
        var len = name.length;
        return len >= suffix.length && name.substr(len - suffix.length) == suffix;
    }

    static inline function isAtomToString(funExpr: ElixirAST): Bool {
        return switch (funExpr.def) {
            case ECapture(inner, _) :
                switch (inner.def) {
                    case ERemoteCall({def: EVar(m)}, f, _) if (m == "Atom" && f == "to_string"): true;
                    case EField({def: EVar(m2)}, f2) if (m2 == "Atom" && f2 == "to_string"): true;
                    default: false;
                }
            case ERemoteCall({def: EVar(m3)}, f3, _) if (m3 == "Atom" && f3 == "to_string"): true;
            default: false;
        };
    }

    public static function presenceHelpersNormalizationPass(ast: ElixirAST): ElixirAST {
        // First determine if we're inside a Presence module scope, then transform children
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var inPresence = (n.metadata?.isPresence == true) || isPresenceModuleName(name);
                    if (!inPresence) return n;
                    var newBody = [];
                    for (b in body) newBody.push(rewriteEnumMapForPresence(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);

                case EDefmodule(name, doBlock):
                    var inPresence2 = (n.metadata?.isPresence == true) || isPresenceModuleName(name);
                    if (!inPresence2) return n;
                    makeASTWithMeta(EDefmodule(name, rewriteEnumMapForPresence(doBlock)), n.metadata, n.pos);

                default:
                    n;
            }
        });
    }

    static function rewriteEnumMapForPresence(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                // Enum.map(Map.keys(arg), &Atom.to_string/1) -> Map.keys(arg)
                case ERemoteCall({def: EVar(enumMod)}, "map", [keysExpr, fun]) if (enumMod == "Enum" && isAtomToString(fun)):
                    switch (keysExpr.def) {
                        case ERemoteCall({def: EVar(mapMod)}, "keys", [arg]) if (mapMod == "Map"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "keys", [arg]), x.metadata, x.pos);
                        default:
                            x;
                    }
                default:
                    x;
            }
        });
    }
}

#end
