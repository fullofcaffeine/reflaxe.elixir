package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceSelfToWebPresenceRewriteTransforms
 *
 * WHAT
 * - Rewrites remote calls using __MODULE__.* inside Presence modules to
 *   <App>Web.Presence.*. This matches snapshot expectations where helper
 *   functions reference the concrete Web Presence module explicitly.
 *
 * WHY
 * - Generated Presence helpers previously used __MODULE__.track/update/untrack,
 *   which is idiomatic but differs from the snapshots (MyAppWeb.Presence.*).
 *   To keep tests focused on code shape rather than aliasing, rewrite only in
 *   Presence modules by structure (no app-name heuristics).
 *
 * HOW
 * - Traverse AST; when inside an EDefmodule/EModule that looks like a Presence
 *   module (metadata.isPresence = true or name ends with Web.Presence), replace
 *   ERemoteCall(__MODULE__, fn, args) with ERemoteCall(<App>Web.Presence, fn, args).
 */
class PresenceSelfToWebPresenceRewriteTransforms {
    static inline function deriveWebPresence(moduleName:String): Null<String> {
        if (moduleName == null) return null;
        var idx = moduleName.indexOf("Web.Presence");
        if (idx > 0) {
            // already a Web.Presence module; keep as-is
            return moduleName;
        }
        // Derive app prefix from PhoenixMapper
        var appPrefix: String = null;
        try appPrefix = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (_:Dynamic) {}
        if (appPrefix == null || appPrefix.length == 0) return null;
        return appPrefix + "Web.Presence";
    }

    static inline function looksLikePresenceModule(name:String, meta:Dynamic):Bool {
        if (meta != null && meta.isPresence == true) return true;
        if (name == null) return false;
        return StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web.Presence");
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        #if sys
        try sys.io.File.append('/tmp/presence_self_rewrite.log', true).writeString('[PresenceSelfRewrite] pass start\n') catch (_:Dynamic) {}
        #end
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefmodule(name, doBlock) if (looksLikePresenceModule(name, n.metadata)):
                    var webPresence = deriveWebPresence(name);
                    if (webPresence == null) return n;
                    var newDo = rewriteSelfCalls(doBlock, webPresence);
                    #if sys
                    try sys.io.File.append('/tmp/presence_self_rewrite.log', true).writeString('[PresenceSelfRewrite] EDefmodule ' + name + ' -> ' + webPresence + "\n") catch (_:Dynamic) {}
                    #end
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                case EModule(name, attrs, body) if (looksLikePresenceModule(name, n.metadata)):
                    var webPresence2 = deriveWebPresence(name);
                    if (webPresence2 == null) return n;
                    var newBody = [for (b in body) rewriteSelfCalls(b, webPresence2)];
                    #if sys
                    try sys.io.File.append('/tmp/presence_self_rewrite.log', true).writeString('[PresenceSelfRewrite] EModule ' + name + ' -> ' + webPresence2 + "\n") catch (_:Dynamic) {}
                    #end
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteSelfCalls(sub: ElixirAST, webPresence:String): ElixirAST {
        return ElixirASTTransformer.transformNode(sub, function(m: ElixirAST): ElixirAST {
            return switch (m.def) {
                case EVar(v) if (v == "__MODULE__"):
                    // Broad fallback: replace bare __MODULE__ with concrete Web.Presence
                    makeASTWithMeta(EVar(webPresence), m.metadata, m.pos);
                case ERemoteCall(mod, fn, args):
                    var isSelf = switch (mod.def) { case EVar(v) if (v == "__MODULE__"): true; default: false; };
                    if (isSelf) {
                        #if sys
                        try sys.io.File.append('/tmp/presence_self_rewrite.log', true).writeString('[PresenceSelfRewrite] rewrite ' + fn + ' to ' + webPresence + '.' + fn + "\n") catch (_:Dynamic) {}
                        #end
                        makeASTWithMeta(ERemoteCall(makeAST(EVar(webPresence)), fn, args), m.metadata, m.pos);
                    } else m;
                case ECall(target, fn2, args2) if (target != null):
                    var isSelf2 = switch (target.def) { case EVar(v2) if (v2 == "__MODULE__"): true; default: false; };
                    if (isSelf2) {
                        #if sys
                        try sys.io.File.append('/tmp/presence_self_rewrite.log', true).writeString('[PresenceSelfRewrite] rewrite (ECall) ' + fn2 + ' to ' + webPresence + '.' + fn2 + "\n") catch (_:Dynamic) {}
                        #end
                        makeASTWithMeta(ERemoteCall(makeAST(EVar(webPresence)), fn2, args2), m.metadata, m.pos);
                    } else m;
                default:
                    m;
            }
        });
    }
}

#end
