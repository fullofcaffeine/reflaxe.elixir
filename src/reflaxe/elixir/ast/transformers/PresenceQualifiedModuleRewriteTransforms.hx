package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceQualifiedModuleRewriteTransforms
 *
 * WHAT
 * - Rewrites fully-qualified presence module calls from `<App>.Presence.*` to
 *   `<App>Web.Presence.*` to match idiomatic Phoenix usage and test expectations.
 *
 * WHY
 * - Presence runtime APIs are provided by the app’s Web Presence module (e.g.,
 *   `MyAppWeb.Presence`). Calls to `<App>.Presence.*` are non-idiomatic and
 *   cause snapshot mismatches in presence tests.
 *
 * HOW
 * - Traverse the AST and match ERemoteCall/ECall/ECapture where the module is
 *   exactly `<Prefix>.Presence` (one dot) and not already `<Prefix>Web.Presence`.
 *   Replace the module with `<Prefix>Web.Presence` preserving function and args.
 * - Shape-based only; no app-name heuristics beyond module suffix check.
 */
class PresenceQualifiedModuleRewriteTransforms {
    static inline function toWebPresence(modName:String): Null<String> {
        if (modName == null) return null;
        // Only rewrite modules that look like <Prefix>.Presence (one dot) and are not already <Prefix>Web.Presence
        if (StringTools.endsWith(modName, ".Presence") && modName.indexOf("Web.Presence") == -1) {
            var parts = modName.split(".");
            if (parts.length != 2) return null;
            var prefix = parts[0];
            if (prefix == null || prefix.length == 0) return null;
            // Never rewrite framework roots like Phoenix.Presence → PhoenixWeb.Presence.
            if (prefix == "Phoenix") return null;
            if (StringTools.endsWith(prefix, "Web")) return null;
            return prefix + "Web.Presence";
        }
        return null;
    }

    static inline function toWebPresenceFromField(moduleExpr: ElixirAST): Null<String> {
        return switch (moduleExpr.def) {
            case EField({def: EVar(prefix)}, "Presence"):
                if (prefix != null && prefix.length > 0 && prefix != "Phoenix" && !StringTools.endsWith(prefix, "Web")) {
                    prefix + "Web.Presence";
                } else null;
            default:
                null;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(module, fn, args):
                    var repl = switch (module.def) {
                        case EVar(m): toWebPresence(m);
                        default: toWebPresenceFromField(module);
                    };
                    if (repl != null) makeASTWithMeta(ERemoteCall(makeAST(EVar(repl)), fn, args), n.metadata, n.pos) else n;
                case ECall(target, callName, callArgs) if (target != null):
                    var replacementModule = switch (target.def) {
                        case EVar(moduleName): toWebPresence(moduleName);
                        default: toWebPresenceFromField(target);
                    };
                    if (replacementModule != null) makeASTWithMeta(ERemoteCall(makeAST(EVar(replacementModule)), callName, callArgs), n.metadata, n.pos) else n;
                case ECapture(expr, arity):
                    switch (expr.def) {
                        case ERemoteCall(capturedModule, capturedName, capturedArgs):
                            var replacementModule = switch (capturedModule.def) {
                                case EVar(moduleName): toWebPresence(moduleName);
                                default: toWebPresenceFromField(capturedModule);
                            };
                            if (replacementModule != null) makeASTWithMeta(ECapture(makeAST(ERemoteCall(makeAST(EVar(replacementModule)), capturedName, capturedArgs)), arity), n.metadata, n.pos) else n;
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
