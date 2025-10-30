package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * LiveViewTypedEventBridgeTransforms
 *
 * WHAT
 * - Auto‑generates Phoenix LiveView `handle_event/3` callbacks for modules with a
 *   typed `handleEvent(enum, socket)` function by mapping string events + params
 *   to the module’s typed enum, then delegating to `handleEvent/2`.
 *
 * WHY
 * - Keep business logic fully typed in Haxe while exposing idiomatic LiveView
 *   handlers required by Phoenix at runtime. Removes the need for any app‑side
 *   string fallbacks and avoids name heuristics.
 *
 * HOW
 * - For @:liveview modules, detect a `def handleEvent(event, socket)` function.
 * - Inspect its body to find a `case event do ... end` with enum patterns like:
 *     - `:cancel_edit` (0‑arity)
 *     - `{:set_priority, id, priority}` (n‑arity)
 * - For each clause, emit:
 *     def handle_event("set_priority", params, socket) do
 *       id = Map.get(params, "id") |> (is_binary/1 ? String.to_integer/1 : & &1)
 *       priority = Map.get(params, "priority")
 *       {:noreply, handleEvent({:set_priority, id, priority}, socket)}
 *     end
 * - Binder → params mapping is purely shape‑based:
 *     - Binder name → Map.get(params, snake_case(binder))
 *     - id/_id → integer when binary
 *     - binder named "params" → entire params map
 * - Existing `handle_event/3` clauses are preserved; generated ones fill gaps only.
 *
 * EXAMPLES
 * Haxe:
 *   public static function handleEvent(ev: TodoEvent, socket: Socket<Assigns>) {
 *     var s = switch (ev) {
 *       case CancelEdit: ...;
 *       case SetPriority(id, p): ...;
 *     }
 *     return NoReply(s);
 *   }
 * Elixir (added):
 *   def handle_event("cancel_edit", _params, socket), do: {:noreply, handleEvent(:cancel_edit, socket)}
 *   def handle_event("set_priority", params, socket), do: {:noreply, handleEvent({:set_priority, ...}, socket)}
 */
@:nullSafety(Off)
class LiveViewTypedEventBridgeTransforms {

    // Entry point
    public static function transformPass(ast: ElixirAST): ElixirAST {
        #if sys Sys.println('[TypedEventBridge] pass start'); #end
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var out = synthesizeCallbacks(body, n.metadata, n.pos);
                    #if sys Sys.println('[TypedEventBridge] module=' + name + ' callbacks=' + Std.string(countHandleEvent(out))); #end
                    makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
                case EDefmodule(modName, doBlock):
                    var stmts = switch (doBlock.def) { case EDo(s): s; case EBlock(s2): s2; default: []; };
                    var out = synthesizeCallbacks(stmts, n.metadata, n.pos);
                    #if sys Sys.println('[TypedEventBridge] defmodule=' + modName + ' callbacks=' + Std.string(countHandleEvent(out))); #end
                    makeASTWithMeta(EDefmodule(modName, makeAST(EBlock(out))), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function countHandleEvent(body:Array<ElixirAST>):Int {
        var c = 0;
        for (s in body) switch (s.def) {
            case EDef("handle_event", args, _, _) if (args != null && args.length == 3): c++;
            default:
        }
        return c;
    }

    static function synthesizeCallbacks(body: Array<ElixirAST>, meta: ElixirMetadata, pos: haxe.macro.Expr.Position): Array<ElixirAST> {
        // Build fresh callbacks from the typed handleEvent/2 case. These are considered
        // the single source of truth. We then drop any existing handle_event/3 with the
        // same literal event and insert our deterministic definitions.
        var synthesized = collectFromHandleEvent(body, meta, pos);
        if (synthesized == null || synthesized.length == 0) return body; // nothing to do

        var toReplace = new Map<String,Bool>();
        for (cb in synthesized) toReplace.set(cb.event, true);

        var out:Array<ElixirAST> = [];
        for (s in body) switch (s.def) {
            case EDef("handle_event", args, _, _ ) if (args.length == 3):
                switch (args[0]) {
                    case PLiteral({def: EString(ev)}) if (toReplace.exists(ev)):
                        // Drop existing definition; will be replaced by synthesized one
                        // (ensures no app-coupled/broken wrappers linger)
                    default:
                        out.push(s);
                }
            default:
                out.push(s);
        }
        // Append synthesized callbacks (deterministic order)
        for (cb in synthesized) out.push(cb.def);
        return out;
    }

    static function collectFromHandleEvent(body: Array<ElixirAST>, meta: ElixirMetadata, pos: haxe.macro.Expr.Position): Array<{event:String, def:ElixirAST}> {
        var out:Array<{event:String, def:ElixirAST}> = [];
        for (stmt in body) switch (stmt.def) {
            case EDef(fname, args, _, bdy) if ((fname == "handleEvent" || fname == "handle_event") && args.length == 2):
                var evArg = patternVarName(args[0]);
                var caseNode = findCaseOnVar(bdy, evArg);
                if (caseNode != null) {
                    switch (caseNode.def) {
                        case ECase(_, clauses):
                            for (cl in clauses) {
                                var info = patternToEventAndBinders(cl.pattern);
                                if (info != null) {
                                    var def = buildCallback(info.event, info.binders, cl.body, meta, pos);
                                    out.push({event: info.event, def: def});
                                }
                            }
                        default:
                    }
                }
            default:
        }
        return out;
    }

    static inline function patternVarName(p:EPattern): Null<String> {
        return switch (p) { case PVar(n): n; default: null; }
    }

    static function findCaseOnVar(body: ElixirAST, evArgName: Null<String>): Null<ElixirAST> {
        if (evArgName == null) return null;
        var found:Null<ElixirAST> = null;
        function walk(n: ElixirAST): Void {
            if (found != null || n == null) return;
            switch (n.def) {
                case ECase(scrut, _):
                    switch (scrut.def) { case EVar(v) if (v == evArgName): found = n; default: }
                    if (found == null) {
                        // keep walking
                        switch (n.def) { case ECase(_, clauses): for (c in clauses) walk(c.body); default: }
                    }
                case EBlock(es) | EDo(es): for (e in es) walk(e);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                default:
            }
        }
        walk(body);
        return found;
    }

    static function patternToEventAndBinders(p: EPattern): Null<{event:String, binders:Array<String>}> {
        return switch (p) {
            case PLiteral({def: EAtom(a)}): { event: (a : String), binders: [] };
            case PTuple(items) if (items.length >= 1):
                switch (items[0]) {
                    case PLiteral({def: EAtom(a)}):
                        var binders:Array<String> = [];
                        for (i in 1...items.length) switch (items[i]) { case PVar(n): binders.push(n); default: }
                        { event: (a : String), binders: binders };
                    default: null;
                }
            default: null;
        }
    }

    static function makeNoReply(sock:ElixirAST):ElixirAST {
        return makeAST(ETuple([ makeAST(EAtom(ElixirAtom.raw("noreply"))), sock ]));
    }

    static inline function needsIntConversion(varName:String):Bool {
        return varName == "id" || StringTools.endsWith(varName, "_id");
    }

    static function buildExtract(varName:String):ElixirAST {
        if (varName == "params") return makeAST(EVar("params"));
        var key = reflaxe.elixir.ast.NameUtils.toSnakeCase(varName);
        var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar("params")), makeAST(EString(key)) ]));
        if (!needsIntConversion(varName)) return get;
        var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
        var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
        return makeAST(EIf(isBin, toInt, get));
    }

    static function extractSocketExpr(expr: ElixirAST): { prelude: Array<ElixirAST>, socket: ElixirAST } {
        switch (expr.def) {
            case ETuple(elts) if (elts.length == 2):
                switch (elts[0].def) { case EAtom(a) if ((a : String) == "noreply"): return { prelude: [], socket: elts[1] }; default: }
            case EBlock(exprs) if (exprs.length > 0):
                var pre = exprs.slice(0, exprs.length - 1);
                var last = exprs[exprs.length - 1];
                var inner = extractSocketExpr(last);
                return { prelude: pre.concat(inner.prelude), socket: inner.socket };
            default:
        }
        return { prelude: [], socket: expr };
    }

    static function buildCallback(eventName:String, binders:Array<String>, branchExpr:ElixirAST, meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
        var extracts:Array<ElixirAST> = [];
        var reserved = new Map<String,Bool>();
        reserved.set("socket", true); reserved.set("params", true); reserved.set("event", true);
        // NOTE: We do not inline the typed branch body (`branchExpr`) here because
        // `handleEvent/2` is the single source of truth for behavior. Instead, we
        // delegate to `handleEvent/2` and normalize its return into
        // `{:noreply, socket}`. This avoids double-running any branch preludes and
        // prevents nested {:noreply, {:noreply, socket}} shapes.
        var finalBinders = binders != null ? binders.copy() : [];
        // Build param extracts (skip reserved)
        for (b in finalBinders) if (!reserved.exists(b)) extracts.push(makeAST(EMatch(PVar(b), buildExtract(b))));

        // Construct typed enum value to delegate to handleEvent/2
        var tagAtom = makeAST(EAtom(ElixirAtom.raw(eventName)));
        var typed:ElixirAST = null;
        if (finalBinders.length == 0) {
            typed = tagAtom; // 0‑arity → bare atom
        } else {
            var args:Array<ElixirAST> = [for (b in finalBinders) makeAST(EVar(b))];
            typed = makeAST(ETuple([tagAtom].concat(args)));
        }

        var delegate = makeAST(ECall(null, "handleEvent", [ typed, makeAST(EVar("socket")) ]));
        var blk:Array<ElixirAST> = [];
        for (e in extracts) blk.push(e);
        // Normalize the result of handleEvent/2 into {:noreply, socket}
        var noreplyAtom = makeAST(EAtom(ElixirAtom.raw("noreply")));
        var clause1:ECaseClause = {
            pattern: PTuple([ PLiteral(noreplyAtom), PVar("s") ]),
            guard: null,
            body: makeAST(ETuple([ noreplyAtom, makeAST(EVar("s")) ]))
        };
        var clause2:ECaseClause = {
            pattern: PVar("s2"),
            guard: null,
            body: makeAST(ETuple([ noreplyAtom, makeAST(EVar("s2")) ]))
        };
        var normalized = makeAST(ECase(delegate, [ clause1, clause2 ]));
        blk.push(normalized);
        var funBody = makeAST(EBlock(blk));
        return makeASTWithMeta(
            EDef(
                "handle_event",
                [ PLiteral(makeAST(EString(eventName))), PVar("params"), PVar("socket") ],
                null,
                funBody
            ),
            meta,
            pos
        );
    }
}

#end
