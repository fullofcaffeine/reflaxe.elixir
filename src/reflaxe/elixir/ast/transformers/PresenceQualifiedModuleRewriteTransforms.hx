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
        // Only rewrite modules that look like <Prefix>.Presence and are not already <Prefix>Web.Presence
        if (StringTools.endsWith(modName, ".Presence") && modName.indexOf("Web.Presence") == -1) {
            // Use PhoenixMapper to derive the canonical app prefix (shape-based, not name-coupled)
            var appPrefix: String = null;
            try appPrefix = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (_:Dynamic) {}
            if (appPrefix == null || appPrefix.length == 0) return null;
            return appPrefix + "Web.Presence";
        }
        return null;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(module, fn, args):
                    var ms = switch (module.def) { case EVar(m): m; default: null; };
                    var repl = ms != null ? toWebPresence(ms) : null;
                    if (repl != null) makeASTWithMeta(ERemoteCall(makeAST(EVar(repl)), fn, args), n.metadata, n.pos) else n;
                case ECall(target, fn2, args2) if (target != null):
                    var ms2 = switch (target.def) { case EVar(m2): m2; default: null; };
                    var repl2 = ms2 != null ? toWebPresence(ms2) : null;
                    if (repl2 != null) makeASTWithMeta(ERemoteCall(makeAST(EVar(repl2)), fn2, args2), n.metadata, n.pos) else n;
                case ECapture(expr, arity):
                    switch (expr.def) {
                        case ERemoteCall(module2, fn3, args3):
                            var ms3 = switch (module2.def) { case EVar(m3): m3; default: null; };
                            var repl3 = ms3 != null ? toWebPresence(ms3) : null;
                            if (repl3 != null) makeASTWithMeta(ECapture(makeAST(ERemoteCall(makeAST(EVar(repl3)), fn3, args3)), arity), n.metadata, n.pos) else n;
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
