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
    static inline function isHandleEvent2(name:String, args:Array<EPattern>):Bool {
        if (name != "handle_event") return false;
        return args != null && args.length == 2;
    }

    static function toStringLiteral(s:String):ElixirAST {
        return makeAST(EString(s));
    }

    static function atomToString(a:String):String {
        // Already lowercase atoms represent event names; use as-is
        return a;
    }

    static function makeNoReply(sock:ElixirAST):ElixirAST {
        return makeAST(ETuple([ makeAST(EAtom("no_reply")), sock ]));
    }

    static function needsIntConversion(varName:String):Bool {
        return varName == "id" || StringTools.endsWith(varName, "_id");
    }

    static function buildExtract(varName:String):ElixirAST {
        // Special-case: a binder literally named "params" maps to the whole params map
        if (varName == "params") return makeAST(EVar("params"));
        var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar("params")), toStringLiteral(varName) ]));
        if (!needsIntConversion(varName)) return get;
        // Convert id/_id if binary
        var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
        var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
        return makeAST(EIf(isBin, toInt, get));
    }

    static function buildCallback(eventName:String, binders:Array<String>, originalBody:ElixirAST, meta:ElixirMetadata, pos: haxe.macro.Expr.Position):ElixirAST {
        // def handle_event("event", params, socket) do ... {:noreply, sock} end
        var args = [ PVar("_event"), PVar("params"), PVar("socket") ];
        // Build extraction statements that bind each binder name from params
        var extracts:Array<ElixirAST> = [];
        for (b in binders) {
            var valueExpr = buildExtract(b);
            extracts.push(makeAST(EMatch(PVar(b), valueExpr)));
        }
        var blk:Array<ElixirAST> = [];
        // Params are available; run extracts then return {:noreply, ...}
        for (e in extracts) blk.push(e);
        blk.push(makeNoReply(originalBody));
        var funBody = makeAST(EBlock(blk));
        var def = makeASTWithMeta(EDef("handle_event", [ PVar("\"" + eventName + "\""), PVar("params"), PVar("socket") ], null, funBody), meta, pos);
        return def;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (isLiveViewModule(n, name, body)):
                    var newBody:Array<ElixirAST> = [];
                    var replaced = false;
                    for (stmt in body) {
                        switch (stmt.def) {
                            case EDef(fname, args, _, fbody) if (isHandleEvent2(fname, args)):
                                // try to parse case dispatch
                                var callbacks:Array<ElixirAST> = parseHandleEvent2(stmt, n.metadata, n.pos);
                                if (callbacks != null && callbacks.length > 0) {
                                    for (c in callbacks) newBody.push(c);
                                    replaced = true; // drop original
                                } else {
                                    newBody.push(stmt);
                                }
                            default:
                                newBody.push(stmt);
                        }
                    }
                    // Add a catch-all to avoid crashes if nothing matched
                    if (replaced) {
                        newBody.push(makeAST(EDef("handle_event", [PVar("_event"), PVar("_params"), PVar("socket")], null, makeNoReply(makeAST(EVar("socket"))))));
                    }
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function isLiveViewModule(node:ElixirAST, name:String, body:Array<ElixirAST>):Bool {
        if (node.metadata?.isLiveView == true) return true;
        // Heuristic (shape-based, not app-specific): name ends with "Live"
        if (name != null && StringTools.endsWith(name, "Live")) return true;
        // Or body contains `use <App>Web, :live_view`
        for (b in body) switch (b.def) {
            case EUse(mod, opts) if (opts != null && opts.length > 0):
                for (o in opts) switch (o.def) { case EAtom(a) if (a == "live_view"): return true; default: }
            default:
        }
        return false;
    }

    static function parseHandleEvent2(defNode:ElixirAST, meta:ElixirMetadata, pos:haxe.macro.Expr.Position):Array<ElixirAST> {
        // Expect body: result_socket = case event do ... end ; {:no_reply, result_socket}
        switch (defNode.def) {
            case EDef(_, _, _, body):
                var stmts:Array<ElixirAST> = switch (body.def) {
                    case EBlock(ss): ss;
                    case EDo(ss2): ss2;
                    default: null;
                };
                if (stmts == null || stmts.length < 2) return null;
                // First assignment should be result var = case ...
                var caseNode:Null<ElixirAST> = null;
                switch (stmts[0].def) {
                    case EMatch(PVar(_), expr): caseNode = expr;
                    case EBinary(Match, _, expr2): caseNode = expr2;
                    default:
                }
                switch (caseNode != null ? caseNode.def : null) {
                    case ECase(scrut, clauses):
                        // scrutinee should be `event`
                        switch (scrut.def) { case EVar(v) if (v == "event"): /* ok */ default: return null; }
                        var out:Array<ElixirAST> = [];
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
                            // clause body expected to be helper call producing socket
                            var helperCall:ElixirAST = cl.body;
                            out.push(buildCallback(evName, binders, helperCall, meta, pos));
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
