package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveMountNormalizeTransforms
 *
 * WHAT
 * - Normalizes common LiveView mount/3 flows to ensure required binders are present
 *   and properly assigned:
 *   - Promote wildcard assignments to named binders when names are used later
 *   - Bind `updated_socket` to Phoenix.Component.assign/2 when returned
 *   - Replace undeclared first arg in assign/2 with `socket`
 *   - Handle Phoenix.Component.assign wrapped in an assignment
 *
 * WHY
 * - Late hygiene passes can discard binders that are required later in mount (e.g.,
 *   `now`, `todos`, `assigns`, `updated_socket`), causing undefined-variable errors.
 *   This pass restores the minimal, idiomatic flow in a shape-based manner.
 *
 * HOW
 * - Runs very late in the pipeline. Works within modules ending with "Live" only.
 * - Two phases inside mount body (EBlock):
 *   1) Promote `_ = rhs` to `name = rhs` for known names used later (now/todos/assigns/presence_socket)
 *   2) Normalize Phoenix.Component.assign calls:
 *      - If first arg var is undeclared, replace with `socket`
 *      - If later return uses `updated_socket` and not declared, rewrite call to
 *        `updated_socket = Phoenix.Component.assign(first, second)` preserving metadata
 *      - Supports both bare call statements and calls wrapped in assignments
 *
 * EXAMPLES
 * Haxe (shape):
 *   var now = Date.now();
 *   var assigns = {...}
 *   var presenceSocket = Presence.trackUser(socket, currentUser);
 *   var updatedSocket = LiveView.assignMultiple(presenceSocket, assigns);
 *   return Ok(updatedSocket);
 *
 * Elixir (after):
 *   now = DateTime.utc_now()
 *   assigns = %{...}
 *   updated_socket = Phoenix.Component.assign(socket, assigns)
 *   {:ok, updated_socket}
 */
class LiveMountNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        // Apply directly to any function named "mount" (Phoenix LiveView mount/3),
        // irrespective of module naming, to increase robustness without app-specific heuristics.
        return ElixirASTTransformer.transformNode(ast, function(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EDef(fname, args, guards, body) if (fname == "mount"):
                    var b = body;
                    switch (b.def) {
                        case EBlock(stmts):
                            var declared = new Map<String, Bool>();
                            // Collect declared names in this function
                            for (s in stmts) switch (s.def) {
                                case EMatch(PVar(n), _): declared.set(n, true);
                                case EBinary(Match, left, _):
                                    switch (left.def) { case EVar(n2): declared.set(n2, true); default: }
                                default:
                            }

                            // Helper: laterUses(name)
                            function laterUses(i:Int, name:String):Bool {
                                for (k in i+1...stmts.length) if (usesName(stmts[k], name)) return true; return false;
                            }

                            var out:Array<ElixirAST> = [];
                            for (i in 0...stmts.length) {
                                var s = stmts[i];
                                switch (s.def) {
                                    // Do not promote by literal names here; leave for generic usage-based pass
                                    case EBinary(Match, _, _):
                                        out.push(s);
                                    default:
                                        out.push(s);
                                }
                            }

                            // Second pass: ensure updated_socket assignment present and first arg is socket when undeclared
                            for (i in 0...out.length) switch (out[i].def) {
                                // Bare call statement: Phoenix.Component.assign(socket_like, assigns)
                                case ERemoteCall({def: EVar(mod)}, "assign", [firstArg, secArg]) if (mod == "Phoenix.Component"):
                                    var firstVar: Null<String> = switch (firstArg.def) { case EVar(v): v; default: null; };
                                    if (firstVar != null && !declared.exists(firstVar)) {
                                        // Prefer first function parameter name when available
                                        var paramName:Null<String> = null;
                                        for (a in args) switch (a) { case PVar(nm): paramName = nm; break; default: }
                                        if (paramName != null) firstArg = makeAST(ElixirASTDef.EVar(paramName));
                                    }
                                    var needsBinding = false;
                                    for (k in i+1...out.length) switch (out[k].def) {
                                        case ETuple(elems) if (elems.length == 2):
                                            var okAtom = switch (elems[0].def) { case EAtom(_): true; default: false; };
                                            var secondVar:Null<String> = switch (elems[1].def) { case EVar(vn2): vn2; default: null; };
                                            if (okAtom && secondVar != null) needsBinding = true;
                                        default:
                                    }
                                    if (needsBinding && !declared.exists("updated_socket")) {
                                        // Bind to the actual tuple var name instead of hardcoding
                                        var tupleVar:Null<String> = null;
                                        for (k in i+1...out.length) switch (out[k].def) {
                                            case ETuple(elems2) if (elems2.length == 2):
                                                var ok2 = switch (elems2[0].def) { case EAtom(_): true; default: false; };
                                                switch (elems2[1].def) { case EVar(vn3) if (ok2): tupleVar = vn3; default: }
                                            default:
                                        }
                                        if (tupleVar != null) {
                                            out[i] = makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(tupleVar)), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]))), out[i].metadata, out[i].pos);
                                            declared.set(tupleVar, true);
                                        } else {
                                            out[i] = makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]), out[i].metadata, out[i].pos);
                                        }
                                    } else {
                                        out[i] = makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]), out[i].metadata, out[i].pos);
                                    }
                                // Assignment wrapping the call: updated_socket = Phoenix.Component.assign(presence_socket, assigns)
                                case EBinary(Match, leftVar, { def: ERemoteCall({def: EVar(mod2)}, "assign", args2) }) if (mod2 == "Phoenix.Component"):
                                    // Normalize first arg to declared or nearest function param
                                    var a0 = args2[0];
                                    var a1 = args2[1];
                                    var fv: Null<String> = switch (a0.def) { case EVar(v): v; default: null; };
                                    if (fv != null && !declared.exists(fv)) {
                                        var paramName2:Null<String> = null;
                                        for (a in args) switch (a) { case PVar(nm): paramName2 = nm; break; default: }
                                        if (paramName2 != null) a0 = makeAST(ElixirASTDef.EVar(paramName2));
                                    }
                                    // Ensure binder name aligns with tuple var later
                                    var bindName: Null<String> = switch (leftVar.def) { case EVar(vn): vn; default: null; };
                                    var needsUpd = false;
                                    for (k in i+1...out.length) switch (out[k].def) {
                                        case ETuple(elems2) if (elems2.length == 2):
                                            var ok2 = switch (elems2[0].def) { case EAtom(_): true; default: false; };
                                            var var2:Null<String> = switch (elems2[1].def) { case EVar(vn2): vn2; default: null; };
                                            if (ok2 && var2 != null) needsUpd = true;
                                        default:
                                    }
                                    var finalLeft = leftVar;
                                    if (needsUpd) {
                                        var tupleVar2:Null<String> = null;
                                        for (k in i+1...out.length) switch (out[k].def) {
                                            case ETuple(elems3) if (elems3.length == 2):
                                                var ok3 = switch (elems3[0].def) { case EAtom(_): true; default: false; };
                                                switch (elems3[1].def) { case EVar(vn4) if (ok3): tupleVar2 = vn4; default: }
                                            default:
                                        }
                                        if (tupleVar2 != null) {
                                            finalLeft = makeAST(ElixirASTDef.EVar(tupleVar2));
                                            declared.set(tupleVar2, true);
                                        }
                                    } else if (bindName != null) {
                                        declared.set(bindName, true);
                                    }
                                    out[i] = makeASTWithMeta(EBinary(Match, finalLeft, makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [a0, a1]))), out[i].metadata, out[i].pos);
                                default:
                            }
                            return makeASTWithMeta(EDef(fname, args, guards, makeAST(EBlock(out))), e.metadata, e.pos);
                        case EDo(stmts):
                            // Treat EDo similarly to EBlock for mount normalization
                            var declared = new Map<String, Bool>();
                            for (s in stmts) switch (s.def) {
                                case EMatch(PVar(n), _): declared.set(n, true);
                                case EBinary(Match, left, _):
                                    switch (left.def) { case EVar(n2): declared.set(n2, true); default: }
                                default:
                            }

                            var out:Array<ElixirAST> = [];
                            for (i in 0...stmts.length) out.push(stmts[i]);

                            // Normalize assign/2 calls within EDo blocks as well (shape-based only)
                            for (i in 0...out.length) switch (out[i].def) {
                                case ERemoteCall({def: EVar(mod)}, "assign", [firstArg, secArg]) if (mod == "Phoenix.Component"):
                                    var firstVar: Null<String> = switch (firstArg.def) { case EVar(v): v; default: null; };
                                    if (firstVar != null && !declared.exists(firstVar)) {
                                        var paramName:Null<String> = null;
                                        for (a in args) switch (a) { case PVar(nm): paramName = nm; break; default: }
                                        if (paramName != null) firstArg = makeAST(ElixirASTDef.EVar(paramName));
                                    }
                                    var needsBinding = false;
                                    var tupleVar:Null<String> = null;
                                    for (k in i+1...out.length) switch (out[k].def) {
                                        case ETuple(elems) if (elems.length == 2):
                                            var okAtom = switch (elems[0].def) { case EAtom(_): true; default: false; };
                                            switch (elems[1].def) { case EVar(vn): if (okAtom) { needsBinding = true; tupleVar = vn; } default: }
                                        default:
                                    }
                                    if (needsBinding && tupleVar != null && !declared.exists(tupleVar)) {
                                        out[i] = makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(tupleVar)), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]))), out[i].metadata, out[i].pos);
                                        declared.set(tupleVar, true);
                                    } else {
                                        out[i] = makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]), out[i].metadata, out[i].pos);
                                    }
                                case EBinary(Match, leftVar, { def: ERemoteCall({def: EVar(mod2)}, "assign", args2) }) if (mod2 == "Phoenix.Component"):
                                    var a0 = args2[0];
                                    var a1 = args2[1];
                                    var fv: Null<String> = switch (a0.def) { case EVar(v): v; default: null; };
                                    if (fv != null && !declared.exists(fv)) {
                                        var paramName2:Null<String> = null;
                                        for (a in args) switch (a) { case PVar(nm): paramName2 = nm; break; default: }
                                        if (paramName2 != null) a0 = makeAST(ElixirASTDef.EVar(paramName2));
                                    }
                                    var finalLeft = leftVar;
                                    var needsUpd = false;
                                    var tupleVar2:Null<String> = null;
                                    for (k in i+1...out.length) switch (out[k].def) {
                                        case ETuple(elems2) if (elems2.length == 2):
                                            var ok2 = switch (elems2[0].def) { case EAtom(_): true; default: false; };
                                            switch (elems2[1].def) { case EVar(vn2) if (ok2): needsUpd = true; tupleVar2 = vn2; default: }
                                        default:
                                    }
                                    if (needsUpd && tupleVar2 != null) {
                                        finalLeft = makeAST(ElixirASTDef.EVar(tupleVar2));
                                        declared.set(tupleVar2, true);
                                    }
                                    out[i] = makeASTWithMeta(EBinary(Match, finalLeft, makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [a0, a1]))), out[i].metadata, out[i].pos);
                            default:
                            }
                            return makeASTWithMeta(EDef(fname, args, guards, makeAST(EDo(out))), e.metadata, e.pos);
                        default:
                            return e;
                    }
                default:
                    e;
            }
        });
    }

    static function usesName(n: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt); for (a in args) walk(a);
                case ERemoteCall(tgt2, _, args2): walk(tgt2); for (a2 in args2) walk(a2);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EStructUpdate(base, fields): walk(base); for (f in fields) walk(f.value);
                case ETuple(elems): for (e in elems) walk(e);
                case EString(str):
                    if (str != null) {
                        var i = 0;
                        while (!found && i < str.length) {
                            var idx = str.indexOf("#{", i);
                            if (idx == -1) break;
                            var j = str.indexOf('}', idx + 2);
                            if (j == -1) break;
                            var inner = str.substr(idx + 2, j - (idx + 2));
                            if (inner != null && inner.indexOf(name) != -1) { found = true; break; }
                            i = j + 1;
                        }
                    }
                case ERaw(code):
                    if (code != null && code.indexOf(name) != -1) found = true;
                default:
            }
        }
        walk(n);
        return found;
    }
}

#end
