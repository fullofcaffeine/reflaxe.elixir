package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceWithSocketAssignNormalizeTransforms
 *
 * WHAT
 * - Inside Presence modules, when a function body ends by returning `socket` and
 *   contains a bare Presence.track/update/untrack(...) statement, normalize that
 *   bare call to `socket = Presence.*(...)` so the effect is visible and matches
 *   intended chainable patterns.
 *
 * WHY
 * - Chainable presence helpers often call Presence.* for side effects and then
 *   return the socket. Keeping the effect as an assignment preserves clarity and
 *   matches snapshot expectations, while remaining API-/shape-based.
 *
 * HOW
 * - Scope strictly to Presence modules (metadata.isPresence or module name ends
 *   with ".Presence"/"Web.Presence").
 * - For EBlock ending with EVar("socket"), rewrite the first preceding bare
 *   ERemoteCall to Presence.{track,update,untrack} into an assignment:
 *     `socket = <that call>`.
 * - Does not invent APIs; simply binds the call result to `socket` when the
 *   body returns `socket`.
 */
class PresenceWithSocketAssignNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresenceModule(name, n)):
                    var newBody = [for (b in body) normalize(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (looksLikePresenceModule(name, n)):
                    makeASTWithMeta(EDefmodule(name, normalize(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresenceModule(name:String, node:ElixirAST):Bool {
        if (node != null && node.metadata != null && node.metadata.isPresence == true) return true;
        if (name == null) return false;
        return StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web.Presence");
    }

    static function normalize(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts) if (stmts.length >= 2):
                    var lastIsSocket = switch (stmts[stmts.length - 1].def) { case EVar(v) if (v == "socket"): true; default: false; };
                    if (!lastIsSocket) return x;
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length - 1) {
                        var s = stmts[i];
                        switch (s.def) {
                            case ERemoteCall(mod, func, args) if (isPresenceEffect(mod, func)):
                                out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("socket")), s), s.metadata, s.pos));
                                continue;
                            case EMatch(PWildcard, rhs) if (isPresenceEffectExpr(rhs)):
                                out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("socket")), rhs), s.metadata, s.pos));
                                continue;
                            default:
                        }
                        out.push(s);
                    }
                    out.push(stmts[stmts.length - 1]);
                    makeASTWithMeta(EBlock(out), x.metadata, x.pos);
                case EDo(stmts) if (stmts.length >= 2):
                    var lastIsSocket2 = switch (stmts[stmts.length - 1].def) { case EVar(v2) if (v2 == "socket"): true; default: false; };
                    if (!lastIsSocket2) return x;
                    var out2:Array<ElixirAST> = [];
                    for (i in 0...stmts.length - 1) {
                        var s2 = stmts[i];
                        switch (s2.def) {
                            case ERemoteCall(mod2, func2, args2) if (isPresenceEffect(mod2, func2)):
                                out2.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("socket")), s2), s2.metadata, s2.pos));
                                continue;
                            case EMatch(PWildcard, rhs2) if (isPresenceEffectExpr(rhs2)):
                                out2.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("socket")), rhs2), s2.metadata, s2.pos));
                                continue;
                            default:
                        }
                        out2.push(s2);
                    }
                    out2.push(stmts[stmts.length - 1]);
                    makeASTWithMeta(EDo(out2), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static inline function isPresenceEffect(mod: ElixirAST, func: String): Bool {
        var modName: Null<String> = switch (mod.def) { case EVar(m): m; default: null; };
        if (modName == null) return false;
        var isPresence = (modName == "Phoenix.Presence") || StringTools.endsWith(modName, ".Presence") || (modName == "Presence");
        return isPresence && (func == "track" || func == "update" || func == "untrack");
    }

    static inline function isPresenceEffectExpr(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, func, _): isPresenceEffect(mod, func);
            default: false;
        };
    }
}

#end
