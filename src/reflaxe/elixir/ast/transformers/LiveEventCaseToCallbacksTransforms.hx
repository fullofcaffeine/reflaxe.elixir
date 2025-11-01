package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveEventCaseToCallbacksTransforms
 *
 * WHAT
 * - Rewrites non-idiomatic `handle_event(event, socket)` case-dispatch into
 *   proper Phoenix LiveView `handle_event/3` callbacks, one per event name.
 *
 * WHY
 * - Generated LiveView modules using a two-arg handle_event will never be
 *   called by Phoenix (expects arity-3). Converting to arity-3 restores UI
 *   interactivity without app-specific heuristics.
 *
 * HOW
 * - In modules with isLiveView metadata, locate a definition:
 *   def handle_event(event, socket) do
 *     result_socket = case event do
 *       {:name, var} -> helper(var, socket)
 *       :cancel -> SafeAssigns.set_show_form(...)
 *       {:set_priority, id, p} -> update(id, p, socket)
 *     end
 *     {:no_reply, result_socket}
 *   end
 * - Emit multiple:
 *   def handle_event("name", params, socket) do
 *     {:noreply, helper(extract("var", params), socket)}
 *   end
 *   def handle_event("cancel", _params, socket) do
 *     {:noreply, SafeAssigns.set_show_form(...)}
 *   end
 * - Extraction: for each binder name N in tuple pattern, produce
 *   `vN = Map.get(params, to_string(N))` and pass vN (with a basic `_id`
 *   String.to_integer conversion) into the helper call preserving order.
 */
class LiveEventCaseToCallbacksTransforms {
    static inline function isHandleEventArityTwo(name:String, args:Array<EPattern>):Bool {
        return name == "handle_event" && args != null && args.length == 2;
    }

    static function toStringLiteral(s:String):ElixirAST {
        return makeAST(EString(s));
    }

    static function atomToString(a:reflaxe.elixir.ast.naming.ElixirAtom):String {
        // ElixirAtom already normalized; use as provided
        return (a : String);
    }

    static function makeNoReply(sock:ElixirAST):ElixirAST {
        return makeAST(ETuple([ makeAST(EAtom(reflaxe.elixir.ast.naming.ElixirAtom.raw("noreply"))), sock ]));
    }

    static function needsIntConversion(varName:String):Bool {
        return varName == "id" || StringTools.endsWith(varName, "_id");
    }

    static function buildExtract(varName:String):ElixirAST {
        // Special-case: a binder literally named "params" maps to the whole params map
        if (varName == "params") return makeAST(EVar("params"));
        var key = reflaxe.elixir.ast.NameUtils.toSnakeCase(varName);
        var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar("params")), toStringLiteral(key) ]));
        if (!needsIntConversion(varName)) return get;
        // Convert id/_id if binary
        var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
        var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
        return makeAST(EIf(isBin, toInt, get));
    }

    static function extractSocketExpr(expr: ElixirAST): { prelude: Array<ElixirAST>, socket: ElixirAST } {
        // If the branch returns {:noreply, socket}, unwrap to socket
        switch (expr.def) {
            case ETuple(elts) if (elts.length == 2):
                switch (elts[0].def) {
                    case EAtom(a) if ((a : String) == "noreply"):
                        return { prelude: [], socket: elts[1] };
                    default:
                }
            case EBlock(exprs) if (exprs.length > 0):
                var pre = exprs.slice(0, exprs.length - 1);
                var last = exprs[exprs.length - 1];
                var inner = extractSocketExpr(last);
                return { prelude: pre.concat(inner.prelude), socket: inner.socket };
            default:
        }
        return { prelude: [], socket: expr };
    }

    static function buildCallback(eventName:String, binders:Array<String>, branchExpr:ElixirAST, meta:ElixirMetadata, pos: haxe.macro.Expr.Position):ElixirAST {
        // def handle_event("event", params, socket) do ... {:noreply, sock} end
        // Build extraction statements that bind each binder name from params
        var extracts:Array<ElixirAST> = [];
        // Filter out reserved names that should never be extracted from params
        var reserved = new Map<String,Bool>();
        reserved.set("socket", true);
        reserved.set("params", true);
        reserved.set("event", true);
        // Unwrap {:noreply, socket} if present in branch
        var unwrapped = extractSocketExpr(branchExpr);
        // If pattern binders are empty (e.g., clause pattern was just an atom),
        // infer candidate binders from the socket-producing expression (top-level call args preferred).
        if (binders == null || binders.length == 0) {
            var inferred = inferVarsFromExpr(unwrapped.socket);
            // Keep only non-reserved identifiers
            binders = [for (v in inferred) if (!reserved.exists(v)) v];
        }
        // De-duplicate and filter reserved and non-local identifiers (modules/constants)
        var seen = new Map<String,Bool>();
        var safeBinders:Array<String> = [];
        for (b in binders) if (b != null && b.length > 0 && !reserved.exists(b) && !seen.exists(b) && isLocalVarName(b)) { seen.set(b, true); safeBinders.push(b); }
        // Fallback: if none survived filtering, infer from expression arguments
        if (safeBinders.length == 0) {
            var inferred2 = inferVarsFromExpr(unwrapped.socket);
            for (b in inferred2) if (b != null && b.length > 0 && !reserved.exists(b) && !seen.exists(b) && isLocalVarName(b)) { seen.set(b, true); safeBinders.push(b); }
        }
        for (b in safeBinders) {
            var valueExpr = buildExtract(b);
            extracts.push(makeAST(EMatch(PVar(b), valueExpr)));
        }
        var blk:Array<ElixirAST> = [];
        // First any param extracts, then any branch preludes, then final noreply tuple
        for (e in extracts) blk.push(e);
        for (e in unwrapped.prelude) blk.push(e);
        blk.push(makeNoReply(unwrapped.socket));
        var funBody = makeAST(EBlock(blk));
        // Use `_params` if no binders (0‑arity event); otherwise use `params`.
        var paramsBinder:EPattern = (safeBinders.length == 0) ? PVar("_params") : PVar("params");
        var def = makeASTWithMeta(
            EDef(
                "handle_event",
                [ PLiteral(makeAST(EString(eventName))), paramsBinder, PVar("socket") ],
                null,
                funBody
            ),
            meta,
            pos
        );
        return def;
    }

    static inline function patternVarName(p:EPattern): Null<String> {
        return switch (p) {
            case PVar(n): n;
            case _: null;
        }
    }

    static function inferBodyVars(expr: ElixirAST): Array<String> {
        var acc = new Map<String,Bool>();
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EVar(name):
                    acc.set(name, true);
                case EMatch(PVar(_), rhs):
                    // Do not collect binder name, but traverse RHS
                    walk(rhs);
                case EBinary(Match, left, right):
                    // Skip collecting LHS binders; traverse RHS only conservatively
                    walk(right);
                case EBlock(es) | EDo(es):
                    for (e in es) walk(e);
                case EIf(c,t,e):
                    walk(c); walk(t); if (e != null) walk(e);
                case ECase(e, cs):
                    walk(e); for (cl in cs) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                case ECond(cs):
                    for (cl in cs) { walk(cl.condition); walk(cl.body); }
                case ECall(t,_,as):
                    if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(m,_,as):
                    walk(m); if (as != null) for (a in as) walk(a);
                case EUnary(_, sub):
                    walk(sub);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                default:
                    // Recurse generically when possible
                    // For nodes without direct children, do nothing
            }
        }
        walk(expr);
        return [for (k in acc.keys()) k];
    }

    static function inferVarsFromExpr(expr: ElixirAST): Array<String> {
        if (expr == null || expr.def == null) return [];
        switch (expr.def) {
            case ERemoteCall(_, _, args):
                var names = [];
                for (a in args) switch (a.def) { case EVar(n): names.push(n); default: }
                return names;
            case ECall(_, _, args):
                var names2 = [];
                for (a in args) switch (a.def) { case EVar(n): names2.push(n); default: }
                return names2;
            default:
                return inferBodyVars(expr);
        }
    }

    static inline function isLocalVarName(name: String): Bool {
        if (name == null || name.length == 0) return false;
        var c = name.charAt(0);
        // Local variables in Elixir start with lowercase letters or underscore (we don't want underscore here)
        var isLower = c >= 'a' && c <= 'z';
        var containsDot = name.indexOf('.') != -1;
        return isLower && !containsDot;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    // Collect existing handle_event/3 callbacks keyed by event string
                    var existing = new Map<String, Bool>();
                    for (stmt in body) switch (stmt.def) {
                        case EDef(fname, args, _, _ ) if (fname == "handle_event" && args.length == 3):
                            switch (args[0]) {
                                case PLiteral({def: EString(s)}): existing.set(s, true);
                                default:
                            }
                        default:
                    }

                    var newBody:Array<ElixirAST> = [];
                    var replacedAny = false;
                    for (stmt in body) {
                        switch (stmt.def) {
                            case EDef(fname, args, _, _ ) if (isHandleEventArityTwo(fname, args)):
                                // try to parse case dispatch
                                var callbacks:Array<{event:String, def:ElixirAST}> = parseHandleEventArityTwoCaseDispatch(stmt, n.metadata, n.pos);
                                if (callbacks != null && callbacks.length > 0) {
                                    for (c in callbacks) {
                                        if (!existing.exists(c.event)) {
                                            newBody.push(c.def);
                                            existing.set(c.event, true);
                                        }
                                    }
                                    replacedAny = true; // drop original
                                } else {
                                    // If not a recognized case form, keep as-is
                                    newBody.push(stmt);
                                }
                            case EDef(fname2, args2, g2, b2) if (fname2 == "handle_event" && args2.length == 3):
                                // Keep the first definition for a given literal event, drop duplicates
                                var keep = true;
                                switch (args2[0]) {
                                    case PLiteral({def: EString(s)}):
                                        if (existing.exists(s)) {
                                            // This is the first scan, we already seeded existing from body;
                                            // ensure we only keep the first occurrence we encounter now.
                                            // If newBody already has one for this event, drop this duplicate.
                                            for (d in newBody) switch (d.def) {
                                                case EDef("handle_event", a3, _, _):
                                                    switch (a3[0]) { case PLiteral({def: EString(s2)}) if (s2 == s): keep = false; default: }
                                                default:
                                            }
                                        } else {
                                            existing.set(s, true);
                                        }
                                    default:
                                }
                                if (keep) newBody.push(stmt);
                            default:
                                newBody.push(stmt);
                        }
                    }

                    // Add a catch-all to avoid crashes if nothing matched but only if no catch-all exists
                    if (replacedAny && !hasCatchAllHandleEvent(newBody)) {
                        newBody.push(makeAST(EDef(
                            "handle_event",
                            [PVar("_event"), PVar("_params"), PVar("socket")],
                            null,
                            makeNoReply(makeAST(EVar("socket")))
                        )));
                    }
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);

                // defmodule form
                case EDefmodule(modName, doBlock):
                    var body:Array<ElixirAST> = switch (doBlock.def) {
                        case EDo(stmts): stmts;
                        case EBlock(stmts2): stmts2;
                        default: [];
                    };
                    // seed existing map
                    var existing = new Map<String, Bool>();
                    for (stmt in body) switch (stmt.def) {
                        case EDef(fname, args, _, _ ) if (fname == "handle_event" && args.length == 3):
                            switch (args[0]) { case PLiteral({def: EString(s)}): existing.set(s, true); default: }
                        default:
                    }
                    var out:Array<ElixirAST> = [];
                    var replacedAny = false;
                    for (stmt in body) {
                        switch (stmt.def) {
                            case EDef(fname, args, _, _) if (isHandleEventArityTwo(fname, args)):
                                var callbacks = parseHandleEventArityTwoCaseDispatch(stmt, n.metadata, n.pos);
                                if (callbacks != null && callbacks.length > 0) {
                                    for (c in callbacks) if (!existing.exists(c.event)) { out.push(c.def); existing.set(c.event, true); }
                                    replacedAny = true;
                                } else {
                                    out.push(stmt);
                                }
                            case EDef(fname2, args2, _, _) if (fname2 == "handle_event" && args2.length == 3):
                                var keep = true;
                                switch (args2[0]) {
                                    case PLiteral({def: EString(s)}):
                                        for (d in out) switch (d.def) {
                                            case EDef("handle_event", a3, _, _):
                                                switch (a3[0]) { case PLiteral({def: EString(s2)}) if (s2 == s): keep = false; default: }
                                            default:
                                        }
                                    default:
                                }
                                if (keep) out.push(stmt);
                            default:
                                out.push(stmt);
                        }
                    }
                    if (replacedAny && !hasCatchAllHandleEvent(out)) {
                        out.push(makeAST(EDef("handle_event", [PVar("_event"), PVar("_params"), PVar("socket")], null, makeNoReply(makeAST(EVar("socket"))))));
                    }
                    var rebuiltBody = makeAST(EBlock(out));
                    makeASTWithMeta(EDefmodule(modName, rebuiltBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function hasCatchAllHandleEvent(body:Array<ElixirAST>):Bool {
        for (stmt in body) switch (stmt.def) {
            case EDef(name, args, _, _ ) if (name == "handle_event" && args.length == 3):
                switch (args[0]) {
                    case PVar(v) if (v == "_event"): return true;
                    default:
                }
            default:
        }
        return false;
    }

    static function isLiveViewModule(node:ElixirAST, body:Array<ElixirAST>):Bool {
        if (node.metadata?.phoenixContext == PhoenixContext.LiveView || node.metadata?.isLiveView == true) return true;
        // Or body contains `use <App>Web, :live_view`
        for (b in body) switch (b.def) {
            case EUse(_, opts) if (opts != null && opts.length > 0):
                for (o in opts) switch (o.def) { case EAtom(a) if ((a : String) == "live_view"): return true; default: }
            default:
        }
        return false;
    }

    static function isLiveViewDoBlock(doBlock: ElixirAST): Bool {
        // Heuristic: do-block contains `use <App>Web, :live_view` or has metadata flag bubbled down
        var stmts:Array<ElixirAST> = switch (doBlock.def) {
            case EDo(es): es;
            case EBlock(es2): es2;
            default: [];
        };
        for (b in stmts) switch (b.def) {
            case EUse(_, opts) if (opts != null && opts.length > 0):
                for (o in opts) switch (o.def) { case EAtom(a) if ((a : String) == "live_view"): return true; default: }
            default:
        }
        return false;
    }

    /**
     * Parses a non-idiomatic handle_event/2 implementation that uses a case
     * dispatch on `event` and returns corresponding handle_event/3 callbacks.
     *
     * Naming: "Arity2" to denote we specifically parse the two-argument form
     * (event, socket) to synthesize the proper arity-3 callbacks.
     */
    static function parseHandleEventArityTwoCaseDispatch(defNode:ElixirAST, meta:ElixirMetadata, pos:haxe.macro.Expr.Position):Array<{event:String, def:ElixirAST}> {
        // Expect body: result_socket = case event do ... end ; {:noreply, result_socket}
        switch (defNode.def) {
            case EDef(_, args, _, body) if (args.length == 2):
                var eventArgName = patternVarName(args[0]);
                var stmts:Array<ElixirAST> = switch (body.def) {
                    case EBlock(ss): ss;
                    case EDo(ss2): ss2;
                    default: null;
                };
                if (stmts == null || stmts.length < 1) return null;
                // First assignment should be result var = case ... OR direct case expr
                var candidate:ElixirAST = stmts[0];
                var caseNode:Null<ElixirAST> = null;
                switch (candidate.def) {
                    case EMatch(_, expr): caseNode = expr;
                    default: caseNode = candidate;
                }
                switch (caseNode != null ? caseNode.def : null) {
                    case ECase(scrut, clauses):
                        // scrutinee should be the first function argument (by identity, not name)
                        switch (scrut.def) {
                            case EVar(v): if (eventArgName != null && v != eventArgName) return null; // mismatch, bail
                            default: return null;
                        }
                        var out:Array<{event:String, def:ElixirAST}> = [];
                        for (cl in clauses) {
                            var evName:String = null;
                            var binders:Array<String> = [];
                            switch (cl.pattern) {
                                case PLiteral({def: EAtom(a)}): evName = atomToString(a);
                                case PTuple(ps):
                                    // first element should be atom event name
                                    switch (ps[0]) { case PLiteral({def: EAtom(a)}): evName = atomToString(a); default: }
                                    // remaining binder names
                                    for (i in 1...ps.length) switch (ps[i]) { case PVar(n): binders.push(n); default: }
                                default:
                            }
                            if (evName == null) continue;
                            var cb = buildCallback(evName, binders, cl.body, meta, pos);
                            out.push({event: evName, def: cb});
                        }
                        return out;
                    default:
                        return null;
                }
            default:
                return null;
        }
    }
}

#end
