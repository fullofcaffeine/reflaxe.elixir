package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * PresenceReduceRewriteTransforms
 *
 * WHAT
 * - Rewrites non-idiomatic Presence list construction patterns into a single
 *   Enum.reduce(Map.values(map), [], fn entry, acc -> ... end) with conditional append.
 * - Specifically targets blocks like:
 *     all_users = <Presence>.list("users")
 *     editing_users = []
 *     Enum.each(all_users, fn _ ->
 *       user_id = Reflect.fields(all_users)[0]
 *       1
 *       entry = Map.get(all_users, user_id)
 *       if length(entry.metas) > 0 do
 *         meta = entry.metas[0]
 *         if meta.editingTodoId == todo_id, do: editing_users = Enum.concat(editing_users, [meta])
 *       end
 *     end)
 *     editing_users
 *   and rewrites it to:
 *     Enum.reduce(Map.values(all_users), [], fn entry, acc ->
 *       if length(entry.metas) > 0 do
 *         meta = entry.metas[0]
 *         if meta.editingTodoId == todo_id, do: acc ++ [meta], else: acc
 *       else
 *         acc
 *       end
 *     end)
 *
 * WHY
 * - Generated code from Reflect.fields + Enum.each produces incorrect/verbose code in Presence modules
 *   and leads to warnings (sentinels, unused binders) and non-idiomatic map iteration.
 * - Idiomatic Presence code iterates Map.values/1 and accumulates with reduce/3.
 *
 * HOW
 * - Scope: Only transform inside Presence modules (metadata.isPresence or module name ends with ".Presence" or contains "Web.Presence").
 * - Pattern-match EBlock bodies that initialize an accumulator to [] followed by an Enum.each(...) on a map
 *   and final return of the accumulator var.
 * - Inside the fn body, drop Reflect.fields(list)[0] aliasing and Map.get(map, key) indirection; replace
 *   references to that local (e.g., entry) with the reduce binder ("entry").
 * - Convert any assignment of the form acc = Enum.concat(acc, [expr]) or acc = acc ++ [expr] into
 *   a conditional append expression on the accumulator variable provided to reduce ("acc").
 * - Preserve nested if structure; ensure the reduce function returns the accumulator in all branches.
 *
 * EXAMPLES
 * Haxe:
 *   var allUsers = Presence.list("users");
 *   var editingUsers = [];
 *   for (_ in allUsers) {
 *     var userId = Reflect.fields(allUsers)[0];
 *     var entry = allUsers[userId];
 *     if (entry.metas.length > 0) {
 *       var meta = entry.metas[0];
 *       if (meta.editingTodoId == todoId) editingUsers.push(meta);
 *     }
 *   }
 *   return editingUsers;
 * Elixir (after):
 *   Enum.reduce(Map.values(all_users), [], fn entry, acc ->
 *     if length(entry.metas) > 0 do
 *       meta = entry.metas[0]
 *       if meta.editing_todo_id == todo_id, do: acc ++ [meta], else: acc
 *     else
 *       acc
 *     end
 *   end)
 */
class PresenceReduceRewriteTransforms {
    static inline function safeBinder(name: String): String {
        return (name != null && name.length > 0 && name.charAt(0) == '_') ? name.substr(1) : name;
    }
    static inline function isPresenceModuleName(name: String): Bool {
        // Deprecated: avoid name-based gating; kept for compatibility
        return false;
    }

    /**
     * Ensure we only wrap map inputs with Map.values/1 once.
     * If the given target is already a Map.values(...) call, return it as-is;
     * otherwise, wrap it in Map.values/1.
     */
    static inline function mapValuesOnce(target: ElixirAST): ElixirAST {
        return switch (target.def) {
            case ERemoteCall({def: EVar(mod)}, "values", args) if (mod == "Map" && args != null && args.length == 1):
                target;
            default:
                makeAST(ERemoteCall(makeAST(EVar("Map")), "values", [target]));
        }
    }

    public static function presenceReduceRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var inPresence = (n.metadata?.isPresence == true) || (name != null && name.indexOf("Web.Presence") > 0);
                    if (!inPresence) return n;
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(rewriteInNode(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var looksPresence = (n.metadata?.isPresence == true) || (name != null && name.indexOf("Web.Presence") > 0);
                    if (!looksPresence) return n;
                    makeASTWithMeta(EDefmodule(name, rewriteInNode(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteInNode(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts) if (stmts.length >= 3):
#if debug_presence
                    trace('[PresenceReduceRewrite] Inspecting EBlock with ' + stmts.length + ' statements');
#end
                    // Broad presence-list pattern: listVar = <Presence>.list("users"); acc = []; Enum.each(listVar, fn ...); (optional tail acc)
                    var listVar: Null<String> = null;
                    var listCall: Null<ElixirAST> = null;
                    var accName: Null<String> = null;
                    var listIdx = -1;
                    var accIdx = -1;
                    // 1) Detect listVar assignment to *.Presence.list("users")
                    for (i in 0...stmts.length) switch (stmts[i].def) {
                        case EBinary(Match, left, rhs):
                            var lhsName: Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                            switch (rhs.def) {
                                case ERemoteCall(mod, "list", args) if (args.length == 1):
                                    var argOk = switch (args[0].def) { case EString(s) if (s == "users"): true; default: false; };
                                    if (lhsName != null && argOk) { listVar = lhsName; listCall = rhs; listIdx = i; }
                                default:
                            }
                        case EMatch(pat, rhs):
                            var lhsName2: Null<String> = switch (pat) { case PVar(n): n; default: null; };
                            switch (rhs.def) {
                                case ERemoteCall(mod2, "list", args2) if (args2.length == 1):
                                    var argOk2 = switch (args2[0].def) { case EString(s2) if (s2 == "users"): true; default: false; };
                                    if (lhsName2 != null && argOk2) { listVar = lhsName2; listCall = rhs; listIdx = i; }
                                default:
                            }
                        default:
                    }
#if debug_presence
                    if (listVar != null) trace('[PresenceReduceRewrite] Detected list var: ' + listVar + ' at index ' + listIdx);
#end
                    // 2) Detect acc init to []
                    for (i in 0...stmts.length) switch (stmts[i].def) {
                        case EBinary(Match, l, r):
                            var nm = switch (l.def) { case EVar(n): n; default: null; };
                            switch (r.def) { case EList(items) if (items.length == 0): accName = nm; accIdx = i; default: }
                        case EMatch(PVar(n2), r2):
                            switch (r2.def) { case EList(items2) if (items2.length == 0): accName = n2; accIdx = i; default: }
                        default:
                    }
#if debug_presence
                    if (accName != null) trace('[PresenceReduceRewrite] Detected accumulator: ' + accName + ' at index ' + accIdx);
#end
                    // 3) Detect Enum.each(listVar, fn ... end)
                    var eachAt = -1;
                    var eachNode: Null<ElixirAST> = null;
                    var eachListMatches = false;
                    var eachFn: Null<ElixirAST> = null;
                    if (listVar != null) for (i in 0...stmts.length) switch (stmts[i].def) {
                        case ERemoteCall({def: EVar("Enum")}, "each", args) if (args.length == 2):
                            eachAt = i; eachNode = stmts[i];
                            // Verify first arg is the same list var
                            eachListMatches = switch (args[0].def) { case EVar(n) if (n == listVar): true; default: false; };
                            eachFn = args[1];
                        default:
                    }
                    if (listVar != null && accName != null && eachAt >= 0 && eachListMatches && eachFn != null) {
#if debug_presence
                        trace('[PresenceReduceRewrite] Broad pattern matched. listVar=' + listVar + ' acc=' + accName + ' eachAt=' + eachAt);
#end
                        // Extract inner cond that controls appends to accName
                        var innerBody: Array<ElixirAST> = switch (eachFn.def) { case EFn(clauses) if (clauses.length == 1): switch (clauses[0].body.def) { case EBlock(ss): ss; default: [clauses[0].body]; } default: []; };
                        var cond: Null<ElixirAST> = findAccAppendCond(innerBody, accName);
                        if (cond == null) cond = findMetaFilterCond(innerBody, "meta");
                        if (cond == null) cond = findFirstIfCond(innerBody);
                        // Build reduce(Map.values(listVar), [], fn entry, acc -> if cond' do acc ++ [entry.metas[0]] else acc end end)
                        var binder = "entry";
                        var metaExpr = makeAST(EAccess(makeAST(EField(makeAST(EVar(binder)), "metas")), makeAST(EInteger(0))));
                        // If no condition is discoverable, keep it null so we can append unconditionally
                        // Normalize cond: replace common alias names with binder/meta
                        cond = replaceVarInExpr(cond, "entry", binder);
                        cond = ElixirASTTransformer.transformNode(cond, function(t: ElixirAST): ElixirAST {
                            return switch (t.def) { case EVar(v) if (v.toLowerCase() == "meta"): makeASTWithMeta(metaExpr.def, t.metadata, t.pos); default: t; };
                        });
                        var appendMeta = makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([metaExpr]))));
                        var outerCond = makeAST(EBinary(Greater, makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [ makeAST(EField(makeAST(EVar(binder)), "metas")) ])), makeAST(EInteger(0))));
                        // If no condition could be derived, perform unconditional append when outerCond holds
                        var inner = (cond != null) ? makeAST(EIf(cond, appendMeta, makeAST(EVar("acc")))) : appendMeta;
                        // Return the conditional result directly (no trailing `acc` that discards the branch value)
                        var body = makeAST(EIf(outerCond, inner, makeAST(EVar("acc"))));
                        var reduceFn = makeAST(EFn([{ args: [PVar(binder), PVar("acc")], guard: null, body: body }]));
                        var valuesForListVar = mapValuesOnce(makeAST(EVar(listVar)));
                        var reduceForListVar = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [valuesForListVar, makeAST(EList([])), reduceFn]));
                        var out2: Array<ElixirAST> = [];
                        for (i in 0...stmts.length) {
                            if (i == listIdx) {
                                // keep list assignment as-is to retain local name
                                out2.push(stmts[i]);
                            } else if (i == accIdx) {
                                // replace acc init with reduce call result
                                out2.push(makeAST(EBinary(Match, makeAST(EVar(accName)), reduceForListVar)));
                            } else if (i == eachAt) {
                                // drop Enum.each
                            } else {
                                // drop tail acc if present; otherwise keep
                                var isTail = (i == stmts.length - 1);
                                if (isTail) {
                                    var tailIsAcc = switch (stmts[i].def) { case EVar(v) if (v == accName): true; default: false; };
                                    if (!tailIsAcc) out2.push(stmts[i]);
                                } else out2.push(stmts[i]);
                            }
                        }
                        return makeASTWithMeta(EBlock(out2), x.metadata, x.pos);
                    }
                    var accVar: Null<String> = null;
                    var accInitIdx = -1;
                    // Find accumulator initialization to []
                    for (i in 0...stmts.length) switch (stmts[i].def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) { case EVar(n): switch (rhs.def) { case EList(items) if (items.length == 0): accVar = n; accInitIdx = i; default: } default: }
                        case EMatch(pat, rhs2):
                            switch (pat) { case PVar(n2): switch (rhs2.def) { case EList(items2) if (items2.length == 0): accVar = n2; accInitIdx = i; default: } default: }
                        default:
                    }
                    // If no explicit accumulator variable exists, attempt a synthesis when the block
                    // ends with an empty list [] and contains an Enum.each(list, fn ... end).
                    if (accVar == null) {
                        var tailIsEmptyList = switch (stmts[stmts.length - 1].def) {
                            case EList(items) if (items.length == 0): true;
                            default: false;
                        };
                        var eachPos = -1;
                        var eachList: Null<ElixirAST> = null;
                        var eachClause: Null<{args:Array<EPattern>, body:ElixirAST, guard:Null<ElixirAST>}> = null;
                        for (i in 0...stmts.length) switch (stmts[i].def) {
                            case ERemoteCall(modE, funcE, argsE) if (funcE == "each" && argsE != null && argsE.length == 2):
                                switch (modE.def) {
                                    case EVar(mE) if (mE == "Enum"):
                                        eachPos = i; eachList = argsE[0];
                                        switch (argsE[1].def) { case EFn(csE) if (csE.length == 1): eachClause = csE[0]; default: }
                                    default:
                                }
                            case EBinary(Match, _, rhsE) | EMatch(_, rhsE):
                                switch (rhsE.def) {
                                    case ERemoteCall(modE2, funcE2, argsE2) if (funcE2 == "each" && argsE2 != null && argsE2.length == 2):
                                        switch (modE2.def) { case EVar(mE2) if (mE2 == "Enum"): eachPos = i; eachList = argsE2[0];
                                            switch (argsE2[1].def) { case EFn(csE2) if (csE2.length == 1): eachClause = csE2[0]; default: } default: }
                                    default:
                                }
                            default:
                        }
                        if (tailIsEmptyList && eachPos != -1 && eachList != null && eachClause != null) {
                            // Synthesize reduce(Map.values(list), [], fn entry, acc -> body end)
                            var binder0 = extractSingleArgName(eachClause.args);
                            if (binder0 == null) binder0 = "entry";
                            var fnBodyStmts: Array<ElixirAST> = switch (eachClause.body.def) { case EBlock(ssx): ssx; default: [eachClause.body]; };
                            // Detect `meta = <binder>.metas[0]` alias
                            var metaAlias: Null<String> = null;
                            var metaExpr: Null<ElixirAST> = null;
                            for (s3 in fnBodyStmts) switch (s3.def) {
                                case EBinary(Match, leftB3, rightB3):
                                    switch (rightB3.def) {
                                        case EAccess(arr3, idx3):
                                            switch (arr3.def) { case EField(obj3, field3) if (field3 == "metas"): metaExpr = makeAST(EAccess(makeAST(EField(makeAST(EVar(binder0)), field3)), idx3)); default: }
                                        default:
                                            // not a metas head access
                                    }
                                    switch (leftB3.def) { case EVar(mn3): metaAlias = mn3; default: }
                                default:
                            }
                            // Find inner equality on metaAlias.<field> == someVar
                            var eqCond: Null<ElixirAST> = null;
                            for (s4 in fnBodyStmts) switch (s4.def) {
                                case EIf(c4, _, _):
                                    // Prefer first equality cond that references the meta alias field
                                    switch (c4.def) {
                                        case EBinary(Equal, l4, r4):
                                            var leftIsMetaField = switch (l4.def) { case EField({def: EVar(mv4)}, _fld4) if (metaAlias != null && mv4 == metaAlias): true; default: false; };
                                            if (leftIsMetaField) eqCond = c4;
                                        default:
                                    }
                                default:
                            }
                            // Reduce body: if length(entry.metas) > 0 do
                            var outerCondS = makeAST(EBinary(Greater,
                                makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [ makeAST(EField(makeAST(EVar(binder0)), "metas")) ])),
                                makeAST(EInteger(0))
                            ));
                            var appendVal: ElixirAST = (metaExpr != null) ? metaExpr : makeAST(EAccess(makeAST(EField(makeAST(EVar(binder0)), "metas")), makeAST(EInteger(0))));
                            var appendExpr = makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([appendVal]))));
                            var innerBranch = (eqCond != null) ? makeAST(EIf(eqCond, appendExpr, makeAST(EVar("acc")))) : appendExpr;
                            var reduceBody = makeAST(EIf(outerCondS, innerBranch, makeAST(EVar("acc"))));
                            var reduceFnS = makeAST(EFn([{ args: [PVar(binder0), PVar("acc")], guard: eachClause.guard, body: reduceBody }]));
                            var reduceCallS = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [ mapValuesOnce(eachList), makeAST(EList([])), reduceFnS ]));
                            var outS: Array<ElixirAST> = [];
                            for (i in 0...stmts.length) {
                                if (i == eachPos) {
                                    // drop Enum.each
                                } else if (i == stmts.length - 1) {
                                    // replace final [] with reduceCall
                                    outS.push(reduceCallS);
                                } else {
                                    outS.push(stmts[i]);
                                }
                            }
                            return makeASTWithMeta(EBlock(outS), x.metadata, x.pos);
                        }
                        return x;
                    }
#if debug_presence
                    trace('[PresenceReduceRewrite] Found accumulator init: ' + accVar);
#end

                    // Find Enum.each(...) immediately following (or later in block)
                    var eachIdx = -1;
                    var listTarget: Null<ElixirAST> = null;
                    var fnClause: Null<{args:Array<EPattern>, body:ElixirAST, guard:Null<ElixirAST>}> = null;
                    for (i in accInitIdx+1...stmts.length) switch (stmts[i].def) {
                        case ERemoteCall(mod, func, args) if (func == "each" && args.length == 2):
                            switch (mod.def) { case EVar(m) if (m == "Enum"): listTarget = args[0];
                                switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): fnClause = clauses[0]; eachIdx = i; default: } default: }
                        case EBinary(Match, _, rhs) | EMatch(_, rhs):
                            switch (rhs.def) { case ERemoteCall(mod2, func2, args2) if (func2 == "each" && args2.length == 2):
                                switch (mod2.def) { case EVar(m2) if (m2 == "Enum"): listTarget = args2[0];
                                    switch (args2[1].def) { case EFn(clauses) if (clauses.length == 1): fnClause = clauses[0]; eachIdx = i; default: } default: } default: }
                        default:
                    }
                    if (eachIdx == -1 || listTarget == null || fnClause == null) return x;
#if debug_presence
                    trace('[PresenceReduceRewrite] Found Enum.each on list target: ' + ElixirASTPrinter.print(listTarget, 0));
#end

                    // Prefer when final statement returns the accumulator; if not, continue with synthesis
                    var returnsAcc = switch (stmts[stmts.length - 1].def) { case EVar(vn) if (vn == accVar): true; default: false; };
#if debug_presence
                    trace('[PresenceReduceRewrite] Found final return of accumulator: ' + accVar);
#end

                    // Build Map.values(listTarget) for reduce input
                    var valuesCall = mapValuesOnce(listTarget);

                    // Prepare reduce function body:
                    // - Replace any local 'entry' alias assignments from Map.get(listTarget, key) with binder references
                    // - Drop Reflect.fields(listTarget)[0] aliasing lines and bare numeric sentinels
                    // - Rewrite accVar rebinds to acc
                    var binderName = extractSingleArgName(fnClause.args);
                    if (binderName == null) binderName = "entry"; // synthesize binder when wildcard used

                    var rawStmts: Array<ElixirAST> = switch (fnClause.body.def) { case EBlock(ss): ss; default: [fnClause.body]; };
#if debug_presence
                    trace('[PresenceReduceRewrite] Scanning fn body with ' + rawStmts.length + ' stmts');
                    for (idx in 0...rawStmts.length) {
                        trace('  [raw[' + idx + ']] ' + ElixirASTPrinter.print(rawStmts[idx], 0));
                    }
#end

                    // Fast-path: detect canonical presence iteration shape and synthesize reduce body
                    var hasReflectHead = false;
                    var metaAliasName: Null<String> = null;
                    for (s in rawStmts) {
                        switch (s.def) {
                            case EBinary(Match, leftP, rightP):
#if debug_presence
                                trace('   [match] ' + ElixirASTPrinter.print(s, 0));
#end
                                switch (rightP.def) {
                                    case EAccess(tgtP, _):
                                        switch (tgtP.def) {
                                            case ERemoteCall({def: EVar("Reflect")}, "fields", [argP]) if (astEquals(argP, listTarget)):
                                                hasReflectHead = true;
#if debug_presence
                                                trace('    [+] Detected Reflect.fields(list)[0]');
#end
                                            default:
                                        }
                                    default:
                                }
                                // Capture meta alias assignment for later cond normalization
                                switch (leftP.def) {
                                    case EVar(mn):
                                        switch (rightP.def) {
                                            case EAccess(arrP, _):
                                                switch (arrP.def) {
                                                    case EField(_, fieldP) if (fieldP == "metas"):
                                                        metaAliasName = mn;
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            case EMatch(patP, rightP2):
#if debug_presence
                                trace('   [pattern match] ' + ElixirASTPrinter.print(s, 0));
#end
                                switch (rightP2.def) {
                                    case EAccess(tgtP2, _):
                                        switch (tgtP2.def) {
                                            case ERemoteCall({def: EVar("Reflect")}, "fields", [argP2]) if (astEquals(argP2, listTarget)):
                                                hasReflectHead = true;
#if debug_presence
                                                trace('    [+] Detected Reflect.fields(list)[0] via EMatch');
#end
                                            default:
                                        }
                                    default:
                                }
                                switch (patP) {
                                    case PVar(mn2):
                                        switch (rightP2.def) {
                                            case EAccess(arrP2, _):
                                                switch (arrP2.def) {
                                                    case EField(_, fieldP2) if (fieldP2 == "metas"):
                                                        metaAliasName = mn2;
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                    }
                    if (hasReflectHead) {
#if debug_presence
                        trace('[PresenceReduceRewrite] Detected presence shape; rewriting to Enum.reduce(Map.values(...))');
#end
                        var binderSafe = safeBinder(binderName);
                        var metaExprSyn = makeAST(EAccess(makeAST(EField(makeAST(EVar(binderSafe)), "metas")), makeAST(EInteger(0))));
                        var condFromBody: Null<ElixirAST> = findMetaFilterCond(rawStmts, metaAliasName);
                        // Normalize condition to binder/meta expression
                        if (metaAliasName != null) condFromBody = replaceVarWithExpr(condFromBody, metaAliasName, metaExprSyn);
                        condFromBody = replaceVarInExpr(condFromBody, "entry", binderSafe);
                        var appendMetaSyn = makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([metaExprSyn]))));
                        var outerCondSyn = makeAST(EBinary(Greater, makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [ makeAST(EField(makeAST(EVar(binderSafe)), "metas")) ])), makeAST(EInteger(0))));
                        var innerSyn = (condFromBody != null)
                            ? makeAST(EIf(condFromBody, appendMetaSyn, makeAST(EVar("acc"))))
                            : appendMetaSyn;
                        var bodySyn = makeAST(EIf(outerCondSyn, innerSyn, makeAST(EVar("acc"))));
                        var reduceSynFn = makeAST(EFn([{ args: [PVar(binderSafe), PVar("acc")], guard: fnClause.guard, body: bodySyn }]));
                        var reduceSynCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [valuesCall, makeAST(EList([])), reduceSynFn]));
                        var outSyn: Array<ElixirAST> = [];
                        for (i in 0...stmts.length) {
                            if (i == accInitIdx) outSyn.push(reduceSynCall) else if (i == eachIdx || i == stmts.length - 1) {} else outSyn.push(stmts[i]);
                        }
                        return makeASTWithMeta(EBlock(outSyn), x.metadata, x.pos);
                    }
                    var cleaned: Array<ElixirAST> = [];
                    var localEntryAlias: Null<String> = null;
                    for (s in rawStmts) {
                        var drop = false;
                        switch (s.def) {
                            case EInteger(v) if (v == 0 || v == 1): drop = true; // sentinel
                            case EFloat(f) if (f == 0.0): drop = true;
                            case EBinary(Match, left, right):
                                // Detect: user_id = Reflect.fields(listTarget)[0]
                                switch (right.def) {
                                    case EAccess(tgt, key0):
                                        if (isHeadSelectOfFields(tgt, listTarget)) drop = true;
                                    default:
                                }
                                // Detect: entry = Map.get(listTarget, user_id)
                                if (!drop) switch (left.def) {
                                    case EVar(aliasName):
                                        switch (right.def) {
                                            case ERemoteCall({def: EVar("Map")}, "get", [m, _key]) if (astEquals(m, listTarget)):
                                                localEntryAlias = aliasName; drop = true;
                                            default:
                                        }
                                    default:
                                }
                            case EMatch(pat, right2):
                                switch (right2.def) {
                                    case EAccess(tgt2, key02): if (isHeadSelectOfFields(tgt2, listTarget)) drop = true; default:
                                }
                                if (!drop) switch (pat) {
                                    case PVar(aliasName2):
                                        switch (right2.def) {
                                            case ERemoteCall({def: EVar("Map")}, "get", [m2, _key2]) if (astEquals(m2, listTarget)):
                                                localEntryAlias = aliasName2; drop = true;
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!drop) cleaned.push(s);
                    }

                    // Now rewrite remaining statements:
                    var rewritten: Array<ElixirAST> = [];
                    for (s in cleaned) {
                        var s2 = s;
                        // Replace references to local entry alias with binder
                        if (localEntryAlias != null) s2 = replaceVarInExpr(s2, localEntryAlias, binderName);
                        // Rewrite accVar rebinds to use 'acc'
                        s2 = rewriteAccAppend(s2, accVar, "acc");
                        rewritten.push(s2);
                    }

                    // Generic presence rewrite: synthesize reduce over Map.values even if head alias not detected
                    var condFromBody2: Null<ElixirAST> = findAccAppendCond(rawStmts, accVar);
                    if (condFromBody2 != null) {
                        var binderSafe2 = safeBinder(binderName);
                        var metaExpr2 = makeAST(EAccess(makeAST(EField(makeAST(EVar(binderSafe2)), "metas")), makeAST(EInteger(0))));
                        // Normalize condition to binder/meta
                        if (localEntryAlias != null) condFromBody2 = replaceVarInExpr(condFromBody2, localEntryAlias, binderSafe2);
                        condFromBody2 = replaceVarInExpr(condFromBody2, "entry", binderSafe2);
                        // Replace any meta alias with binder.metas[0]
                        condFromBody2 = ElixirASTTransformer.transformNode(condFromBody2, function(t: ElixirAST): ElixirAST {
                            return switch (t.def) {
                                case EVar(v) if (v.toLowerCase() == "meta"): makeASTWithMeta(metaExpr2.def, t.metadata, t.pos);
                                default: t;
                            };
                        });
                        var appendMeta2 = makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([metaExpr2]))));
                        var outerCond2 = makeAST(EBinary(Greater, makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [ makeAST(EField(makeAST(EVar(binderSafe2)), "metas")) ])), makeAST(EInteger(0))));
                        var inner2 = makeAST(EIf(condFromBody2, appendMeta2, makeAST(EVar("acc"))));
                        var body2 = makeAST(EBlock([
                            makeAST(EIf(outerCond2, inner2, makeAST(EVar("acc")))),
                            makeAST(EVar("acc"))
                        ]));
                        var reduceFn2 = makeAST(EFn([{ args: [PVar(binderSafe2), PVar("acc")], guard: fnClause.guard, body: body2 }]));
                        var reduceCall2 = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [valuesCall, makeAST(EList([])), reduceFn2]));
                        var out2: Array<ElixirAST> = [];
                        for (i in 0...stmts.length) {
                            if (i == accInitIdx) out2.push(reduceCall2) else if (i == eachIdx || i == stmts.length - 1) {} else out2.push(stmts[i]);
                        }
                        return makeASTWithMeta(EBlock(out2), x.metadata, x.pos);
                    }

                    // Attempt to synthesize a clean nested conditional reduce body for Presence shape
                    var synthesized: Null<ElixirAST> = tryBuildPresenceReduceBody(rewritten, binderName);
                    
                    // Ensure the body returns the accumulator in all paths
                    var bodyExpr: ElixirAST = (synthesized != null) ? synthesized : switch (rewritten.length) {
                        case 0: makeAST(EVar("acc"));
                        default:
                            var last = rewritten[rewritten.length - 1];
                            var needsAccTail = switch (last.def) { case EVar(nm) if (nm == "acc"): false; default: true; };
                            if (needsAccTail) makeAST(EBlock(rewritten.concat([makeAST(EVar("acc"))]))) else makeAST(EBlock(rewritten));
                    };

                    // Sanitize nested assignment to use acc, drop sentinels, and replace alias with binder
                    bodyExpr = ElixirASTTransformer.transformNode(bodyExpr, function(t: ElixirAST): ElixirAST {
                        return switch (t.def) {
                            case EBinary(Match, leftT, rhsT):
                                switch (leftT.def) {
                                    case EVar(lhsT) if (lhsT == accVar):
                                        var repl = rewriteAccAppend(t, accVar, "acc");
                                        if (repl != null) makeASTWithMeta(EBinary(Match, makeAST(EVar("acc")), repl), t.metadata, t.pos) else t;
                                    default: t;
                                }
                            case EInteger(v) if (v == 0 || v == 1): makeASTWithMeta(EBlock([]), t.metadata, t.pos);
                            case EFloat(f) if (f == 0.0): makeASTWithMeta(EBlock([]), t.metadata, t.pos);
                            default: t;
                        }
                    });
                    if (localEntryAlias != null) bodyExpr = replaceVarInExpr(bodyExpr, localEntryAlias, binderName);

                    var reduceFn = makeAST(EFn([{ args: [PVar(binderName), PVar("acc")], guard: fnClause.guard, body: bodyExpr }]));
                    var reduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [valuesCall, makeAST(EList([])), reduceFn]));

                    // Rebuild the block: keep statements up to (but not including) accInit, then insert reduceCall, drop each+final acc
                    var out: Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        if (i == accInitIdx) {
                            // Replace the accumulator init with reduce result (do not keep original init)
                            out.push(reduceCall);
                        } else if (i == eachIdx || i == stmts.length - 1) {
                            // drop Enum.each and final acc return
                        } else {
                            out.push(stmts[i]);
                        }
                    }
                    makeASTWithMeta(EBlock(out), x.metadata, x.pos);

                default:
                    x;
            }
        });
    }

    static inline function extractSingleArgName(args: Array<EPattern>): Null<String> {
        if (args == null || args.length == 0) return null;
        return switch (args[0]) { case PVar(n): n; default: null; };
    }

    static function isHeadSelectOfFields(target: ElixirAST, listExpr: ElixirAST): Bool {
        return switch (target.def) {
            case ERemoteCall({def: EVar("Reflect")}, "fields", [arg]) if (astEquals(arg, listExpr)): true;
            case ERemoteCall({def: EVar("Map")}, "keys", [arg2]) if (astEquals(arg2, listExpr)): true;
            default: false;
        };
    }

    static function astEquals(a: ElixirAST, b: ElixirAST): Bool {
        return ElixirASTPrinter.print(a, 0) == ElixirASTPrinter.print(b, 0);
    }

    static function replaceVarInExpr(n: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function rewriteAccAppend(n: ElixirAST, accName: String, accVarName: String): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBinary(Match, left, rhs):
                    // acc = Enum.concat(acc, [expr]) -> acc = acc ++ [expr]
                    switch (left.def) {
                        case EVar(lv) if (lv == accName):
                            // Enum.concat(acc, [expr])
                            switch (rhs.def) {
                                case ERemoteCall({def: EVar("Enum")}, "concat", [a0, a1]):
                                    switch (a0.def) {
                                        case EVar(v0) if (v0 == accName):
                                            switch (a1.def) {
                                                case EList(items) if (items.length == 1):
                                                    var newRhs = makeAST(EBinary(Concat, makeAST(EVar(accVarName)), makeAST(EList([items[0]]))));
                                                    makeASTWithMeta(EBinary(Match, makeAST(EVar(accVarName)), newRhs), x.metadata, x.pos);
                                                default: x;
                                            }
                                        default: x;
                                    }
                                case EBinary(Concat, llist, rlist):
                                    // acc = acc ++ [expr]
                                    switch (llist.def) {
                                        case EVar(v1) if (v1 == accName):
                                            makeASTWithMeta(EBinary(Match, makeAST(EVar(accVarName)), makeAST(EBinary(Concat, makeAST(EVar(accVarName)), rlist))), x.metadata, x.pos);
                                        default: x;
                                    }
                                default:
                                    x;
                            }
                        default:
                            x;
                    }
                default:
                    x;
            }
        });
    }

    static function tryBuildPresenceReduceBody(stmts: Array<ElixirAST>, binder: String): Null<ElixirAST> {
        // Expect roughly:
        // if length(entry.metas) > 0 do
        //   meta = entry.metas[0]
        //   if meta.editingTodoId == todo_id, do: <append>, else: acc
        // else acc
        var outerIf: Null<{cond:ElixirAST, thenBr:ElixirAST, elseBr:ElixirAST}> = null;
        for (s in stmts) switch (s.def) {
            case EIf(c, t, e): outerIf = {cond:c, thenBr:t, elseBr:(e == null ? makeAST(EVar("acc")) : e)}; break;
            default:
        }
        if (outerIf == null) return null;
        // Normalize outer condition to use binder
        var outerCond = replaceVarInExpr(outerIf.cond, binder, binder); // no-op; used for consistency
        // In then branch, look for meta index and inner if
        var thenStmts: Array<ElixirAST> = switch (outerIf.thenBr.def) { case EBlock(ss): ss; default: [outerIf.thenBr]; };
        var metaExpr: Null<ElixirAST> = null;
        var metaAlias: Null<String> = null;
        var innerIf: Null<ElixirAST> = null;
        for (t in thenStmts) switch (t.def) {
            case EBinary(Match, leftB, right):
                switch (right.def) {
                    case EAccess(arr, idx):
                        // entry.metas[0] -> binder.metas[0]
                        switch (arr.def) {
                            case EField(obj, field) if (field == "metas"):
                                metaExpr = makeAST(EAccess(makeAST(EField(makeAST(EVar(binder)), field)), idx));
                                switch (leftB.def) { case EVar(mv): metaAlias = mv; default: }
                            default:
                        }
                    default:
                }
            case EIf(_c2, _t2, _e2): innerIf = t;
            default:
        }
        if (innerIf == null) return null;
        // Prefer inner predicate that references meta alias when available
        var innerCond: ElixirAST = findMetaFilterCond(thenStmts, metaAlias);
        if (innerCond == null) innerCond = switch (innerIf.def) { case EIf(c2, _, _): c2; default: null; };
        if (innerCond == null) return null;
        // Normalize inner condition to use binder/metaExpr
        if (metaAlias != null && metaExpr != null) innerCond = replaceVarWithExpr(innerCond, metaAlias, metaExpr);
        // Also normalize any lingering entry alias to binder
        innerCond = replaceVarInExpr(innerCond, objString(makeAST(EVar("entry"))), binder);
        // Build acc ++ [meta]
        var appendMeta: ElixirAST = makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([ metaExpr != null ? metaExpr : makeAST(EAccess(makeAST(EField(makeAST(EVar(binder)), "metas")), makeAST(EInteger(0)))) ]))));
        var newInner = makeAST(EIf(innerCond, appendMeta, makeAST(EVar("acc"))));
        var newOuter = makeAST(EIf(outerCond, newInner, makeAST(EVar("acc"))));
        return makeAST(EBlock([newOuter, makeAST(EVar("acc"))]));
    }

    static inline function objString(obj: ElixirAST): String {
        return switch (obj.def) { case EVar(n): n; default: ""; };
    }

    static function replaceVarWithExpr(n: ElixirAST, from: String, toExpr: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(name) if (name == from): makeASTWithMeta(toExpr.def, x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function findMetaFilterCond(nodes: Array<ElixirAST>, metaAlias: Null<String>): Null<ElixirAST> {
        if (nodes == null) return null;
        for (n in nodes) {
            var c = findMetaFilterCondInNode(n, metaAlias);
            if (c != null) return c;
        }
        return null;
    }

    static function findMetaFilterCondInNode(n: ElixirAST, metaAlias: Null<String>): Null<ElixirAST> {
        if (n == null || metaAlias == null) return null;
        return switch (n.def) {
            case EIf(cond, thenBr, elseBr):
                if (exprUsesVar(cond, metaAlias)) cond
                else {
                    var a = findMetaFilterCondInNode(thenBr, metaAlias);
                    if (a != null) a else findMetaFilterCondInNode(elseBr, metaAlias);
                }
            case EBlock(ss): findMetaFilterCond(ss, metaAlias);
            default: null;
        };
    }

    static function exprUsesVar(e: ElixirAST, name: String): Bool {
        var used = false;
        ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case EVar(v) if (v == name): used = true;
                default:
            }
            return x;
        });
        return used;
    }

    static function findAccAppendCond(nodes: Array<ElixirAST>, accName: String): Null<ElixirAST> {
        if (nodes == null) return null;
        for (n in nodes) {
            var c = findAccAppendCondInNode(n, accName);
            if (c != null) return c;
        }
        return null;
    }

    static function findAccAppendCondInNode(n: ElixirAST, accName: String): Null<ElixirAST> {
        if (n == null) return null;
        return switch (n.def) {
            case EIf(cond, thenBr, elseBr):
                if (branchAppendsAcc(thenBr, accName)) cond
                else {
                    var a = findAccAppendCondInNode(thenBr, accName);
                    if (a != null) a else findAccAppendCondInNode(elseBr, accName);
                }
            case EBlock(ss): findAccAppendCond(ss, accName);
            default: null;
        };
    }

    static function branchAppendsAcc(expr: ElixirAST, accName: String): Bool {
        var found = false;
        switch (expr?.def) {
            case EBlock(ss):
                for (s in ss) if (isAccAppendAssign(s, accName)) { found = true; break; }
            default:
                if (isAccAppendAssign(expr, accName)) found = true;
        }
        return found;
    }

    static function findFirstIfCond(nodes: Array<ElixirAST>): Null<ElixirAST> {
        if (nodes == null) return null;
        for (n in nodes) {
            var c = findFirstIfCondInNode(n);
            if (c != null) return c;
        }
        return null;
    }

    static function findFirstIfCondInNode(n: ElixirAST): Null<ElixirAST> {
        if (n == null) return null;
        return switch (n.def) {
            case EIf(cond, thenBr, elseBr): cond;
            case EBlock(ss): findFirstIfCond(ss);
            default: null;
        };
    }

    static function isAccAppendAssign(s: ElixirAST, accName: String): Bool {
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                switch (left.def) {
                    case EVar(v) if (v == accName):
                        switch (rhs.def) {
                            case ERemoteCall({def: EVar("Enum")}, "concat", [a0, _]):
                                switch (a0.def) { case EVar(v0) if (v0 == accName): true; default: false; }
                            case EBinary(Concat, llist, _):
                                switch (llist.def) { case EVar(v1) if (v1 == accName): true; default: false; }
                            default: false;
                        }
                    default: false;
                }
            default: false;
        };
    }
}

#end
