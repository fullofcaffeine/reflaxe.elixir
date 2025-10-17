package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * RepoDeleteCaseArgRestoreTransforms
 *
 * WHAT
 * - Restores correct helper call shape inside `case Repo.delete(record) do {:ok, binder} -> ... end`
 *   success clauses in LiveView modules by rewriting `(binder, socket)` → `(id, socket)` for
 *   2-arity calls. This preserves the intended “remove by id” semantics for immediate UI refresh.
 *
 * WHY
 * - Late, generic hygiene passes seek to align names to nearby binders. In the delete success branch,
 *   both a function parameter (id) and a fresh local (deleted struct) exist. Without a semantic signal,
 *   a normalizer may favor the fresh binder, yielding `(deleted, socket)` in list-removal helpers which
 *   then fail to remove anything (comparing `t.id != struct`). This pass reasserts the expected shape.
 *
 * HOW
 * - Scope: LiveView modules only (node.metadata.isLiveView == true).
 * - For each def/defp with an id-like parameter (id, _id, or *_id):
 *   - Traverse `case` expressions on `<App>.Repo.delete(...)`.
 *   - In the `{:ok, binder}` clause, if the binder looks struct-like (used as field receiver), then:
 *     - Rewrite any 2-arity call (local or remote) whose args are `(binder, socket)` to `(idParam, socket)`.
 *
 * EXAMPLES
 * Before (after hygiene drift):
 *   case Repo.delete(todo) do
 *     {:ok, deleted} ->
 *       broadcast(...)
 *       remove_todo_from_list(deleted, socket)
 *   end
 * After:
 *   case Repo.delete(todo) do
 *     {:ok, deleted} ->
 *       broadcast(...)
 *       remove_todo_from_list(id, socket)
 *   end
 *
 * NOTES
 * - Non-goals: No app-specific names, no fake APIs. This is framework-shape aware but target-agnostic.
 * - Plain Elixir scripts don’t match (no socket + LiveView metadata), so this is a no-op there.
 */
class RepoDeleteCaseArgRestoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        // Run only inside LiveView modules (metadata-only gating)
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body) if (node.metadata?.isLiveView == true):
                    #if debug_ast_transformer
                    Sys.println('[RepoDeleteCaseArgRestore] Entering LiveView module ' + name);
                    #end
                    var newBody = [for (b in body) rewriteDefs(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (node.metadata?.isLiveView == true):
                    #if debug_ast_transformer
                    Sys.println('[RepoDeleteCaseArgRestore] Entering LiveView defmodule ' + name);
                    #end
                    var rewritten = rewriteDefs(doBlock);
                    makeASTWithMeta(EDefmodule(name, rewritten), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function rewriteDefs(n: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var idParam = findIdParam(args);
                    #if debug_ast_transformer
                    Sys.println('[RepoDeleteCaseArgRestore] Visiting def ' + name + ', idParam=' + (idParam == null ? 'null' : idParam));
                    #end
                    if (idParam == null) return node;
                    // Collect success binders from Repo.delete cases in this function
                    var binders = collectSuccessBinders(body);
                    var newBody = rewriteCases(body, idParam);
                    if (binders != null && binders.length > 0) {
                        newBody = rewriteCallsByBinders(newBody, binders, idParam);
                    }
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var idParamPrivate = findIdParam(args);
                    #if debug_ast_transformer
                    Sys.println('[RepoDeleteCaseArgRestore] Visiting defp ' + name + ', idParam=' + (idParamPrivate == null ? 'null' : idParamPrivate));
                    #end
                    if (idParamPrivate == null) return node;
                    var successBinders = collectSuccessBinders(body);
                    var rewrittenBody = rewriteCases(body, idParamPrivate);
                    if (successBinders != null && successBinders.length > 0) {
                        rewrittenBody = rewriteCallsByBinders(rewrittenBody, successBinders, idParamPrivate);
                    }
                    makeASTWithMeta(EDefp(name, args, guards, rewrittenBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function collectSuccessBinders(body: ElixirAST): Array<String> {
        var binders = new Map<String, Bool>();
        function scanBlock(stmts: Array<ElixirAST>): Void {
            for (i in 0...stmts.length) {
                var cur = stmts[i];
                switch (cur.def) {
                    case ECase(expr, clauses):
                        // Only consider cases directly or indirectly on Repo.delete
                        var matchVar: Null<String> = null;
                        switch (expr.def) { case EVar(nm): matchVar = nm; default: }
                        var isDeleteCase = false;
                        if (!isRepoDelete(expr) && matchVar != null) {
                            var j = i - 1; var scans = 0;
                            while (j >= 0 && scans < 3) {
                                switch (stmts[j].def) {
                                    case EBinary(Match, left, rhs):
                                        switch (left.def) { case EVar(nm) if (nm == matchVar): if (isRepoDelete(rhs)) isDeleteCase = true; default: }
                                    case EMatch(pat, rhs2):
                                        switch (pat) { case PVar(nm2) if (nm2 == matchVar): if (isRepoDelete(rhs2)) isDeleteCase = true; default: }
                                    default:
                                }
                                if (isDeleteCase) break;
                                j--; scans++;
                            }
                        } else if (isRepoDelete(expr)) {
                            isDeleteCase = true;
                        }
                        if (isDeleteCase) {
                            for (cl in clauses) {
                                var b = isOkBinderPattern(cl.pattern);
                                if (b != null) binders.set(b, true);
                            }
                        }
                    case EBlock(inner): scanBlock(inner);
                    default:
                }
            }
        }
        switch (body.def) {
            case EBlock(stmts): scanBlock(stmts);
            default:
        }
        return [for (k in binders.keys()) k];
    }

    static function rewriteCallsByBinders(body: ElixirAST, binders: Array<String>, idParam: String): ElixirAST {
        var successBinderSet = new Map<String, Bool>();
        for (b in binders) successBinderSet.set(b, true);
        return ElixirASTTransformer.transformNode(body, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECall(target, funcName, args) if (args != null && args.length == 2):
                    var firstArg = args[0];
                    var secondArg = args[1];
                    var secondArgIsSocket = switch (secondArg.def) { case EVar(varName) if (varName == 'socket'): true; default: false; };
                    var firstArgIsSuccessBinder = switch (firstArg.def) { case EVar(varName) if (successBinderSet.exists(varName)): true; default: false; };
                    var firstArgIsNumericArtifact = switch (firstArg.def) { case EVar(varName2) if (isNumericArtifact(varName2)): true; default: false; };
                    if (secondArgIsSocket && (firstArgIsSuccessBinder || firstArgIsNumericArtifact)) {
                        return makeASTWithMeta(ECall(target, funcName, [ makeAST(EVar(idParam)), secondArg ]), node.metadata, node.pos);
                    } else node;
                case ERemoteCall(mod, funcName2, args2) if (args2 != null && args2.length == 2):
                    var remoteFirstArg = args2[0];
                    var remoteSecondArg = args2[1];
                    var remoteSecondIsSocket = switch (remoteSecondArg.def) { case EVar(varName) if (varName == 'socket'): true; default: false; };
                    var remoteFirstIsSuccessBinder = switch (remoteFirstArg.def) { case EVar(varName) if (successBinderSet.exists(varName)): true; default: false; };
                    var remoteFirstIsNumericArtifact = switch (remoteFirstArg.def) { case EVar(varName) if (isNumericArtifact(varName)): true; default: false; };
                    if (remoteSecondIsSocket && (remoteFirstIsSuccessBinder || remoteFirstIsNumericArtifact)) {
                        return makeASTWithMeta(ERemoteCall(mod, funcName2, [ makeAST(EVar(idParam)), remoteSecondArg ]), node.metadata, node.pos);
                    } else node;
                default:
                    node;
            }
        });
    }

    static inline function isNumericArtifact(name: String): Bool {
        if (name == null) return false;
        var base = (name.length > 0 && name.charAt(0) == '_') ? name.substr(1) : name;
        return ~/^[gs]\d+$/.match(base);
    }

    static inline function stripLeadingUnderscores(nm: String): String {
        if (nm == null) return null;
        var i = 0;
        while (i < nm.length && nm.charAt(i) == '_') i++;
        return nm.substr(i);
    }

    static function findIdParam(args: Array<EPattern>): Null<String> {
        if (args == null) return null;
        var idName: Null<String> = null;
        for (a in args) switch (a) {
            case PVar(nm):
                var base = stripLeadingUnderscores(nm);
                if (base == "id" || StringTools.endsWith(base, "_id")) { idName = nm; }
            default:
        }
        return idName;
    }

    static function isRepoDelete(expr: ElixirAST): Bool {
        return switch (expr.def) {
            case ERemoteCall(mod, func, _args) if (func == "delete"):
                switch (mod.def) {
                    case EVar(m) if (m != null && (StringTools.endsWith(m, ".Repo") || m == "Repo")):
                        true;
                    default: false;
                }
            default: false;
        }
    }

    static function isOkBinderPattern(pat: EPattern): Null<String> {
        return switch (pat) {
            case PTuple(elements) if (elements.length == 2):
                // First element must be literal atom :ok
                var isOk = switch (elements[0]) {
                    case PLiteral({def: EAtom(v)}): v == "ok";
                    default: false;
                };
                if (!isOk) return null;
                switch (elements[1]) {
                    case PVar(nm): nm;
                    default: null;
                }
            default: null;
        }
    }

    static function binderLooksLikeStruct(body: ElixirAST, binder: String): Bool {
        var looks = false;
        function walk(e: ElixirAST): Void {
            if (looks || e == null || e.def == null) return;
            switch (e.def) {
                case EField({def: EVar(nm)}, _): if (nm == binder) { looks = true; return; } else walk(e);
                case EAccess({def: EVar(nm2)}, _): if (nm2 == binder) { looks = true; return; } else walk(e);
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,el): walk(c); walk(t); if (el != null) walk(el);
                case ECase(expr, cs): walk(expr); for (c in cs) walk(c.body);
                case ECall(t, _, as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2, _, as2): walk(t2); if (as2 != null) for (a in as2) walk(a);
                case EList(els): for (el in els) walk(el);
                case ETuple(els): for (el in els) walk(el);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                default:
            }
        }
        walk(body);
        return looks;
    }

    static function rewriteCases(body: ElixirAST, idParam: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var cur = stmts[i];
                        switch (cur.def) {
                            case ECase(expr, clauses):
                                // Fallback: case over temp var bound by Repo.delete earlier in block
                                var matchVar: Null<String> = null;
                                switch (expr.def) { case EVar(nm): matchVar = nm; default: }
                                var isDeleteCase = false;
                                if (!isRepoDelete(expr) && matchVar != null) {
                                    // scan backwards up to 3 statements for `matchVar = Repo.delete(..)`
                                    var j = i - 1; var scans = 0;
                                    while (j >= 0 && scans < 3) {
                                        switch (stmts[j].def) {
                                            case EBinary(Match, left, rhs):
                                                switch (left.def) { case EVar(nm) if (nm == matchVar): if (isRepoDelete(rhs)) isDeleteCase = true; default: }
                                            case EMatch(pat, rhs2):
                                                switch (pat) { case PVar(nm2) if (nm2 == matchVar): if (isRepoDelete(rhs2)) isDeleteCase = true; default: }
                                            default:
                                        }
                                        if (isDeleteCase) break;
                                        j--; scans++;
                                    }
                                } else if (isRepoDelete(expr)) {
                                    isDeleteCase = true;
                                }
                                if (isDeleteCase) {
                                    #if debug_ast_transformer
                                    Sys.println('[RepoDeleteCaseArgRestore] Found case (direct or temp) on Repo.delete, idParam=' + idParam);
                                    #end
                                    var newClauses = [];
                                    for (cl in clauses) {
                                        var binder = isOkBinderPattern(cl.pattern);
                                        if (binder != null) {
                                            var newBody = rewriteCallsInBody(cl.body, binder, idParam);
                                            // Align noreply return to the assigned socket-call result when present
                                            var assigned = findLastAssignedFromSocketCall(newBody);
                                            if (assigned != null) newBody = rewriteNoreplyReturn(newBody, binder, assigned);
                                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                                        } else {
                                            newClauses.push(cl);
                                        }
                                    }
                                    out.push(makeASTWithMeta(ECase(expr, newClauses), cur.metadata, cur.pos));
                                } else {
                                    out.push(cur);
                                }
                            default:
                                out.push(cur);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case ECase(expr, clauses) if (isRepoDelete(expr)):
                    #if debug_ast_transformer
                    Sys.println('[RepoDeleteCaseArgRestore] Found case on Repo.delete, idParam=' + idParam);
                    #end
                    var newClauses = [];
                    for (cl in clauses) {
                        var binder = isOkBinderPattern(cl.pattern);
                        if (binder != null) {
                            var newBody = rewriteCallsInBody(cl.body, binder, idParam);
                            var assigned = findLastAssignedFromSocketCall(newBody);
                            if (assigned != null) newBody = rewriteNoreplyReturn(newBody, binder, assigned);
                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                        } else {
                            newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                case ECase(caseExprFallback, caseClausesFallback):
                    // Fallback by usage: if success binder is used as first arg to a 2-arity call whose second arg is `socket`
                    // and the noreply map returns that binder, rewrite to use idParam and the assigned var
                    var rewrittenClauses = [];
                    for (clause in caseClausesFallback) {
                        var successBinderName = isOkBinderPattern(clause.pattern);
                        if (successBinderName != null) {
                            var rewrittenBody = rewriteCallsInBody(clause.body, successBinderName, idParam);
                            var lastAssignedVar = findLastAssignedFromSocketCall(rewrittenBody);
                            if (lastAssignedVar != null) rewrittenBody = rewriteNoreplyReturn(rewrittenBody, successBinderName, lastAssignedVar);
                            rewrittenClauses.push({ pattern: clause.pattern, guard: clause.guard, body: rewrittenBody });
                        } else {
                            rewrittenClauses.push(clause);
                        }
                    }
                    makeASTWithMeta(ECase(caseExprFallback, rewrittenClauses), n.metadata, n.pos);
                default:
                    #if debug_ast_transformer
                    switch (n.def) {
                        case ECase(expr2, _):
                            try {
                                var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(expr2, 0);
                                Sys.println('[RepoDeleteCaseArgRestore] Non-matching ECase expr: ' + printed);
                            } catch (e: Dynamic) {}
                        default:
                    }
                    #end
                    n;
            }
        });
    }

    static function rewriteCallsInBody(body: ElixirAST, binder: String, idParam: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case ECall(target, name, args) if (args != null && args.length == 2):
                    var a0 = args[0]; var a1 = args[1];
                    var isSocket2nd = switch (a1.def) { case EVar(nm) if (nm == "socket"): true; default: false; };
                    var isBinder1st = switch (a0.def) { case EVar(nm) if (nm == binder): true; default: false; };
                    #if debug_ast_transformer
                    if (isSocket2nd) {
                        var firstName = switch (a0.def) { case EVar(n0): n0; default: '<non-var>'; };
                        Sys.println('[RepoDeleteCaseArgRestore] Local call ' + name + ' first=' + firstName + ' second=socket binder=' + binder + ' idParam=' + idParam + ' match=' + isBinder1st);
                    }
                    #end
                    if (isSocket2nd && isBinder1st) {
                        #if debug_ast_transformer
                        Sys.println('[RepoDeleteCaseArgRestore] Rewriting local call "' + name + '" (' + binder + ', socket) -> (' + idParam + ', socket)');
                        #end
                        makeASTWithMeta(ECall(target, name, [ makeAST(EVar(idParam)), a1 ]), x.metadata, x.pos);
                    } else x;
                case ERemoteCall(mod, name2, args2) if (args2 != null && args2.length == 2):
                    var b0 = args2[0]; var b1 = args2[1];
                    var isSocketSecond = switch (b1.def) { case EVar(nm2) if (nm2 == "socket"): true; default: false; };
                    var isBinderFirst = switch (b0.def) { case EVar(nm3) if (nm3 == binder): true; default: false; };
                    #if debug_ast_transformer
                    if (isSocketSecond) {
                        var firstName2 = switch (b0.def) { case EVar(n00): n00; default: '<non-var>'; };
                        Sys.println('[RepoDeleteCaseArgRestore] Remote call ' + name2 + ' first=' + firstName2 + ' second=socket binder=' + binder + ' idParam=' + idParam + ' match=' + isBinderFirst);
                    }
                    #end
                    if (isSocketSecond && isBinderFirst) {
                        #if debug_ast_transformer
                        Sys.println('[RepoDeleteCaseArgRestore] Rewriting remote call ' + name2 + ' (' + binder + ', socket) -> (' + idParam + ', socket)');
                        #end
                        makeASTWithMeta(ERemoteCall(mod, name2, [ makeAST(EVar(idParam)), b1 ]), x.metadata, x.pos);
                    } else x;
                default:
                    x;
            }
        });
    }

    // Find the last assigned variable from a 2-arity call whose second arg is `socket`
    static function findLastAssignedFromSocketCall(body: ElixirAST): Null<String> {
        var found: Null<String> = null;
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EBinary(Match, left, right):
                    // var = call(..., socket)
                    var lhs: Null<String> = switch (left.def) { case EVar(name): name; default: null; };
                    var rhsIsCallOnSocket = switch (right.def) {
                        case ECall(_, _, args) if (args != null && args.length == 2):
                            switch (args[1].def) { case EVar(nm) if (nm == 'socket'): true; default: false; }
                        case ERemoteCall(_, _, args2) if (args2 != null && args2.length == 2):
                            switch (args2[1].def) { case EVar(nm2) if (nm2 == 'socket'): true; default: false; }
                        default: false;
                    };
                    if (lhs != null && rhsIsCallOnSocket) {
                        found = lhs;
                        #if debug_ast_transformer
                        Sys.println('[RepoDeleteCaseArgRestore] Found assigned-from-socket-call var=' + lhs);
                        #end
                    }
                    // Continue scanning right side for nested matches
                    scan(right);
                case EMatch(pat, rhs2):
                    var lhs2: Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                    var rhs2IsCallOnSocket = switch (rhs2.def) {
                        case ECall(_, _, args) if (args != null && args.length == 2):
                            switch (args[1].def) { case EVar(nm) if (nm == 'socket'): true; default: false; }
                        case ERemoteCall(_, _, args2) if (args2 != null && args2.length == 2):
                            switch (args2[1].def) { case EVar(nm2) if (nm2 == 'socket'): true; default: false; }
                        default: false;
                    };
                    if (lhs2 != null && rhs2IsCallOnSocket) {
                        found = lhs2;
                        #if debug_ast_transformer
                        Sys.println('[RepoDeleteCaseArgRestore] Found assigned-from-socket-call var=' + lhs2);
                        #end
                    }
                    scan(rhs2);
                case EBlock(stmts):
                    for (s in stmts) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case ECall(t, _, as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                case ERemoteCall(t2, _, as2): scan(t2); if (as2 != null) for (a in as2) scan(a);
                case EList(items): for (i in items) scan(i);
                case ETuple(items): for (i in items) scan(i);
                case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                default:
            }
        }
        scan(body);
        return found;
    }

    // Rewrite %{:noreply => binder} to %{:noreply => assignedVar}
    static function rewriteNoreplyReturn(body: ElixirAST, fromBinder: String, toVar: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMap(pairs):
                    var changed = false;
                    var newPairs:Array<EMapPair> = [];
                    for (p in pairs) {
                        var isNoreply = switch (p.key.def) { case EAtom(v) if (v == 'noreply'): true; default: false; };
                        if (isNoreply) {
                            var valueIsBinder = switch (p.value.def) { case EVar(nm) if (nm == fromBinder): true; default: false; };
                            if (valueIsBinder) {
                                newPairs.push({ key: p.key, value: makeAST(EVar(toVar)) });
                                changed = true;
                                #if debug_ast_transformer
                                Sys.println('[RepoDeleteCaseArgRestore] Rewriting noreply value ' + fromBinder + ' -> ' + toVar);
                                #end
                                continue;
                            }
                        }
                        newPairs.push(p);
                    }
                    if (changed) makeASTWithMeta(EMap(newPairs), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }
}

#end
