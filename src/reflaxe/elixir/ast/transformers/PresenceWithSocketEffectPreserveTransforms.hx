package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceWithSocketEffectPreserveTransforms
 *
 * WHAT
 * - In function bodies that end by returning `socket`, preserve any Presence
 *   effect calls (track/update/untrack) immediately preceding the return by
 *   rewriting assignments `socket = Presence.*(...)` or bare calls to
 *   `_ = Presence.*(...)`.
 *
 * WHY
 * - Some hygiene/cleanup passes may eliminate assignments to `socket` when the
 *   function ultimately returns the original `socket`, causing the effectful
 *   Presence call to disappear. This transformation ensures those effect calls
 *   are retained without changing the return value.
 *
 * HOW
 * - For EDef/EDefp bodies that are EBlock/EDo and whose last statement is
 *   `EVar("socket")`:
 *   - Scan prior statements; when encountering
 *       `EBinary(Match, EVar("socket"), presenceCall)`
 *     rewrite it to `EMatch(PWildcard, presenceCall)`.
 *   - Also wrap any bare `ERemoteCall(PresenceModule, fn, args)` into
 *     `EMatch(PWildcard, call)`.
 * - Presence module is matched by API shape: Phoenix.Presence, *.Presence, or
 *   Presence alias; functions limited to track/update/untrack.
 */
class PresenceWithSocketEffectPreserveTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    makeASTWithMeta(EDefp(name2, args2, guards2, rewriteBody(body2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts) if (stmts.length >= 2):
                var lastIsSocket = switch (stmts[stmts.length - 1].def) {
                    case EVar(v) if (v == "socket"): true; default: false;
                };
                if (!lastIsSocket) return body;
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length - 1) {
                    var s = stmts[i];
                    var replaced = false;
                    switch (s.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(nm) if (nm == "socket"):
                                    var pc = extractPresenceCall(rhs);
                                    if (pc != null) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, pc), s.metadata, s.pos));
                                        replaced = true;
                                    }
                                default:
                            }
                        case ERemoteCall(_, _, _):
                            if (isPresenceEffectCall(s)) {
                                out.push(makeASTWithMeta(EMatch(PWildcard, s), s.metadata, s.pos));
                                replaced = true;
                            }
                        default:
                    }
                    if (!replaced) out.push(s);
                }
                out.push(stmts[stmts.length - 1]);
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2) if (stmts2.length >= 2):
                // Treat EDo similarly
                var lastIsSocket2 = switch (stmts2[stmts2.length - 1].def) {
                    case EVar(v2) if (v2 == "socket"): true; default: false;
                };
                if (!lastIsSocket2) return body;
                var out2:Array<ElixirAST> = [];
                for (i in 0...stmts2.length - 1) {
                    var s2 = stmts2[i];
                    var replaced2 = false;
                    switch (s2.def) {
                        case EBinary(Match, left2, rhs2):
                            switch (left2.def) {
                                case EVar(nm2) if (nm2 == "socket"):
                                    var pc2 = extractPresenceCall(rhs2);
                                    if (pc2 != null) {
                                        out2.push(makeASTWithMeta(EMatch(PWildcard, pc2), s2.metadata, s2.pos));
                                        replaced2 = true;
                                    }
                                default:
                            }
                        case ERemoteCall(_, _, _):
                            if (isPresenceEffectCall(s2)) {
                                out2.push(makeASTWithMeta(EMatch(PWildcard, s2), s2.metadata, s2.pos));
                                replaced2 = true;
                            }
                        default:
                    }
                    if (!replaced2) out2.push(s2);
                }
                out2.push(stmts2[stmts2.length - 1]);
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }

    static inline function extractPresenceCall(e: ElixirAST): Null<ElixirAST> {
        return switch (e.def) {
            case ERemoteCall(_, _, _): isPresenceEffectCall(e) ? e : null;
            case EBinary(Match, _, r): extractPresenceCall(r);
            case EMatch(_, r2): extractPresenceCall(r2);
            case EParen(inner): extractPresenceCall(inner);
            default: null;
        }
    }

    static inline function isPresenceEffectCall(n: ElixirAST): Bool {
        return switch (n.def) {
            case ERemoteCall(mod, func, _):
                var modName: Null<String> = switch (mod.def) { case EVar(m): m; default: null; };
                if (modName == null) false else {
                    var isPresence = (modName == "Phoenix.Presence") || StringTools.endsWith(modName, ".Presence") || (modName == "Presence");
                    isPresence && (func == "track" || func == "update" || func == "untrack");
                }
            default: false;
        }
    }
}

#end

