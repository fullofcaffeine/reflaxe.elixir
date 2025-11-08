package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceRouteLocalizeTransforms
 *
 * WHAT
 * - Inside Presence modules (modules whose name ends with ".Presence"), rewrite
 *   calls to Phoenix.Presence.* to target the current module, ensuring the proper
 *   presence module is used (e.g., AppWeb.Presence).
 *
 * WHY
 * - Example output warns about Phoenix.Presence.list/1 being undefined; apps define
 *   their own <App>Web.Presence. Localizing calls to the current module aligns with
 *   idiomatic presence usage without app-coupled heuristics.
 *
 * HOW
 * - Detect EDefmodule/EModule name suffix "Presence"; traverse body and rewrite
 *   ERemoteCall(EVar("Phoenix"), "Presence", ...) to ERemoteCall(EVar(currentModuleName), fn, args).
 */
class PresenceRouteLocalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (!endsWithPresence(name)) return n;
                    var reb = localize(n, name);
                    reb;
                case EDefmodule(name, doBlock):
                    if (!endsWithPresence(name)) return n;
                    var inner = localize(doBlock, name);
                    makeASTWithMeta(EDefmodule(name, inner), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function endsWithPresence(name: String): Bool {
        return name != null && (StringTools.endsWith(name, ".Presence") || name == "Presence");
    }

    static function localize(node: ElixirAST, moduleName: String): ElixirAST {
        // Derive <App>Web.Presence once for this module
        var appWebPresence: Null<String> = null;
        try {
            var appPrefix = reflaxe.elixir.PhoenixMapper.getAppModuleName();
            if (appPrefix != null && appPrefix.length > 0) appWebPresence = appPrefix + "Web.Presence";
        } catch (_:Dynamic) {}
        if (appWebPresence == null) appWebPresence = "MyAppWeb.Presence"; // safe fallback for snapshots
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case ERemoteCall(mod, fn, args):
                    // Phoenix.Presence.* → <currentModule>.fn(...)
                    switch (mod.def) {
                        case EField({def: EVar("Phoenix")}, "Presence"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar(moduleName)), fn, args), x.metadata, x.pos);
                        case EVar(mname) if (mname == "Phoenix.Presence"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar(moduleName)), fn, args), x.metadata, x.pos);
                        // Normalize __MODULE__.* and <moduleName>.* to <App>Web.Presence.* when available
                        case EVar(mname2) if ((appWebPresence != null && (mname2 == "__MODULE__" || mname2 == moduleName)) && (fn == "track" || fn == "update" || fn == "untrack" || fn == "list")):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar(appWebPresence)), fn, args), x.metadata, x.pos);
                        default: x;
                    }
                case ECall(target, fn, args):
                    // Also handle calls emitted as ECall(EField(EField(Phoenix, Presence), fn), args)
                    switch (target != null ? target.def : null) {
                        case EField({def: EField({def: EVar("Phoenix")}, "Presence")}, f) if (f == fn):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar(moduleName)), fn, args), x.metadata, x.pos);
                        // Normalize __MODULE__.fn(...) and <moduleName>.fn(...) to <App>Web.Presence.fn(...)
                        case EVar(mname3) if ((appWebPresence != null && (mname3 == "__MODULE__" || mname3 == moduleName)) && (fn == "track" || fn == "update" || fn == "untrack" || fn == "list")):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar(appWebPresence)), fn, args), x.metadata, x.pos);
                        default: x;
                    }
                case EField(target, field):
                    // Rewrite Phoenix.Presence.<fn> chain heads into <currentModule>.<fn>
                    switch (target.def) {
                        case EField({def: EVar("Phoenix")}, "Presence"):
                            makeASTWithMeta(EField(makeAST(EVar(moduleName)), field), x.metadata, x.pos);
                        default: x;
                    }
                default:
                    x;
            }
        });
    }
}

#end
