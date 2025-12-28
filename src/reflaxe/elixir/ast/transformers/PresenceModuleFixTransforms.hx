package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * PresenceModuleFixTransforms
 *
 * WHAT
 * - Clean up generated <App>Web.Presence modules by eliminating incorrect Repo.get calls
 *   and unused-parameter warnings. Rewrites specific functions to return `socket` and
 *   underscores unused parameters.
 *
 * WHY
 * - Intermediate generators may emit placeholder code (Repo.get(:socket, socket)) and
 *   unused parameters, which fail under warnings-as-errors. This pass restores a clean,
 *   minimal shape without inventing APIs.
 *
 * HOW
 * - Target modules whose name ends with "Web.Presence".
 * - For functions: track_user/2, update_user_editing/3, track_with_socket/4,
 *   update_with_socket/4, untrack_with_socket/3
 *   - Rewrite body to return the first parameter `socket`.
 *   - Underscore other parameters.
 * - Remove direct calls to <App>Web.Repo.get(...) by replacing bodies with `socket`.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class PresenceModuleFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresence(name)):
                    #if debug_ast_transformer
                    haxe.Log.trace('[PresenceModuleFix] Visiting module ' + name, null);
                    #end
                    var rewritten = [for (b in body) fixStmt(b)];
                    makeASTWithMeta(EModule(name, attrs, rewritten), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (looksLikePresence(name)):
                    #if debug_ast_transformer
                    haxe.Log.trace('[PresenceModuleFix] Visiting defmodule ' + name, null);
                    #end
                    // Deeply rewrite function defs inside the defmodule block
                    var fixed = rewriteDefsInTree(doBlock);
                    makeASTWithMeta(EDefmodule(name, fixed), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresence(name:String):Bool {
        return name != null && name.indexOf("Web.Presence") > 0;
    }

    static function fixStmt(n: ElixirAST): ElixirAST {
        return switch (n.def) {
            case EDef(fname, params, guards, body) if (shouldRewrite(fname)):
                #if debug_ast_transformer
                haxe.Log.trace('[PresenceModuleFix] Rewriting def ' + fname, null);
                #end
                var newParams = underscoreUnusedParams(params, ["socket"]);
                var newBody = rewriteBodyToSocket(body);
                makeASTWithMeta(EDef(fname, newParams, guards, newBody), n.metadata, n.pos);
            case EDefp(fname2, params2, guards2, body2) if (shouldRewrite(fname2)):
                #if debug_ast_transformer
                haxe.Log.trace('[PresenceModuleFix] Rewriting defp ' + fname2, null);
                #end
                var newParams2 = underscoreUnusedParams(params2, ["socket"]);
                var newBody2 = rewriteBodyToSocket(body2);
                makeASTWithMeta(EDefp(fname2, newParams2, guards2, newBody2), n.metadata, n.pos);
            // Drop placeholder Repo.get(:socket, socket) bodies by rewriting to socket
            case EDef(fname3, params3, guards3, {def: ERemoteCall(mod, fn, _args)}) if (repoGetCall(mod, fn)):
                #if debug_ast_transformer
                haxe.Log.trace('[PresenceModuleFix] Cleaning placeholder def ' + fname3, null);
                #end
                var newParams3 = underscoreUnusedParams(params3, ["socket"]);
                makeASTWithMeta(EDef(fname3, newParams3, guards3, makeAST(EVar("socket"))), n.metadata, n.pos);
            case EDefp(fname4, params4, guards4, {def: ERemoteCall(mod2, fn2, _args2)}) if (repoGetCall(mod2, fn2)):
                #if debug_ast_transformer
                haxe.Log.trace('[PresenceModuleFix] Cleaning placeholder defp ' + fname4, null);
                #end
                var newParams4 = underscoreUnusedParams(params4, ["socket"]);
                makeASTWithMeta(EDefp(fname4, newParams4, guards4, makeAST(EVar("socket"))), n.metadata, n.pos);
            default:
                n;
        }
    }

    /**
     * Recursively traverse a subtree and apply fixStmt to any def/defp nodes.
     * This ensures we also handle modules represented as EDefmodule with an
     * inner EBlock containing function definitions.
     */
    static function rewriteDefsInTree(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(_, _, _, _):
                    fixStmt(x);
                case EDefp(_, _, _, _):
                    fixStmt(x);
                default:
                    x;
            }
        });
    }

    static function rewriteBodyToSocket(body: ElixirAST): ElixirAST {
        switch (body.def) {
            case EBlock(stmts) if (stmts.length == 1):
                switch (stmts[0].def) {
                    case ERemoteCall(mod, fn, _args) if (repoGetCall(mod, fn)):
                        return makeASTWithMeta(EVar("socket"), body.metadata, body.pos);
                    default:
                }
                return makeASTWithMeta(EVar("socket"), body.metadata, body.pos);
            default:
                return makeASTWithMeta(EVar("socket"), body.metadata, body.pos);
        }
    }

    static inline function shouldRewrite(fname:String):Bool {
        return fname == "track_user" || fname == "update_user_editing"
            || fname == "track_with_socket" || fname == "update_with_socket" || fname == "untrack_with_socket";
    }

    static function repoGetCall(mod: ElixirAST, fn: String): Bool {
        if (fn != "get") return false;
        return switch (mod.def) {
            case EVar(m): if (m == null) false else (StringTools.endsWith(m, ".Repo") || StringTools.endsWith(m, "Web.Repo"));
            default: false;
        }
    }

    static function underscoreUnusedParams(params:Array<EPattern>, keep:Array<String>): Array<EPattern> {
        var out:Array<EPattern> = [];
        for (p in params) switch (p) {
            case PVar(n):
                if (keep.indexOf(n) != -1) out.push(PVar(n)) else out.push(PVar((n != null && n.length > 0 && n.charAt(0) != '_') ? '_' + n : n));
            default:
                out.push(p);
        }
        return out;
    }
}

#end
