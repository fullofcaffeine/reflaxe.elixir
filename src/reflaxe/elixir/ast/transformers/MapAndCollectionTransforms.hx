package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTBuilder;
import reflaxe.elixir.ast.ASTUtils;
import haxe.macro.Expr.Position;

/**
 * MapAndCollectionTransforms: AST transformation passes for maps and collections
 * 
 * WHY: Map and collection operations in Haxe may generate verbose imperative patterns
 *      that should be transformed into idiomatic Elixir functional patterns.
 * 
 * WHAT: Contains transformation passes that optimize map and collection operations:
 *       - Map builder collapse: Convert Map.put sequences to literal maps
 *       - List effect lifting: Extract side-effects from list literals
 * 
 * HOW: Each pass analyzes patterns involving maps and collections and transforms
 *      them into more idiomatic Elixir equivalents.
 * 
 * ARCHITECTURE BENEFITS:
 * - Separation of Concerns: Collection logic isolated from main transformer
 * - Single Responsibility: Each pass handles one collection pattern
 * - Idiomatic Output: Generates functional Elixir patterns
 * - Performance: Eliminates unnecessary intermediate variables
 */
class MapAndCollectionTransforms {
    static inline function safeBinder(name: String): String {
        return (name != null && name.length > 0 && name.charAt(0) == '_') ? name.substr(1) : name;
    }

    /**
     * Enum Each Binder Integrity Pass
     *
     * WHAT
     * - Ensures Enum.each anonymous function bodies use the element binder instead of
     *   indexing into the source list with [0]. Promotes a wildcard binder to a named
     *   binder when the body references the element, and removes stray numeric sentinels
     *   (0/1) that may persist from lowering.
     *
     * WHY
     * - Some lowering paths leave `alias = list[0]` or direct `list[0]` usages in the
     *   body, and occasionally a bare `1` sentinel. This produces non-idiomatic code
     *   and can trigger undefined-variable issues if alias removal happens earlier.
     *   Using the binder consistently is the idiomatic Elixir style.
     *
     * HOW
     * - For ERemoteCall(Enum, "each", [listExpr, fn([binder]) -> body end]):
     *   - Scan body for occurrences of head access `listExpr[0]` and replace them
     *     with the binder variable. If the function argument is a wildcard and the
     *     body references the element, promote the binder to a named variable.
     *   - Drop standalone numeric sentinel literals (1/0, 0.0) inside the body.
     *
     * EXAMPLES
     * Before:
     *   Enum.each(pending, fn _ ->
     *     todo = pending[0]
     *     1
     *     update(todo)
     *   end)
     * After:
     *   Enum.each(pending, fn elem ->
     *     update(elem)
     *   end)
     */
    public static function enumEachBinderIntegrityPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)):
                    var listExpr = args[0];
                    var fnNode = args[1];
                    switch (fnNode.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var clause = clauses[0];
                            // Determine current binder
                            var binderName: Null<String> = null;
                            switch (clause.args.length > 0 ? clause.args[0] : null) {
                                case PVar(n): binderName = n;
                                case PWildcard: binderName = null;
                                default:
                            }

                            // Normalize body into a statement list
                            var stmts: Array<ElixirAST> = switch (clause.body.def) {
                                case EBlock(ss): ss;
                                case EDo(ss2): ss2;
                                default: [clause.body];
                            };

                            // Replace listExpr[0] usages with binder (or a synthesized name)
                            var replacementName = binderName != null ? safeBinder(binderName) : "elem";

                            function replaceHeadAccess(e: ElixirAST): ElixirAST {
                                return ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                                    return switch (x.def) {
                                        case EAccess(target, key):
                                            var isZero = switch (key.def) { case EInteger(v) if (v == 0): true; default: false; };
                                            if (isZero && astEquals(target, listExpr))
                                                makeASTWithMeta(EVar(replacementName), x.metadata, x.pos)
                                            else x;
                                        default: x;
                                    }
                                });
                            }

                            var newStmts: Array<ElixirAST> = [];
                            var promoteFieldsList: Bool = false; // when alias is Reflect.fields(listExpr)[0]
                            var droppedAlias: Null<String> = null;
                            for (s in stmts) {
                                // Drop bare numeric sentinels
                                var keep = switch (s.def) {
                                    case EInteger(v) if (v == 0 || v == 1): false;
                                    case EFloat(f) if (f == 0.0): false;
                                    default: true;
                                };
                                if (!keep) continue;
                                var s1 = replaceHeadAccess(s);
                                // If statement is aliasing binder to a new local, drop it and remember alias
                                switch (s1.def) {
                                    case EBinary(Match, l, r):
                                        var lvar:Null<String> = switch (l.def) { case EVar(nm): nm; default: null; };
                                        var rIsBinder = switch (r.def) { case EVar(nm2) if (nm2 == replacementName): true; default: false; };
                                        if (lvar != null && rIsBinder) { droppedAlias = lvar; continue; }
                                    case EMatch(patX, r2):
                                        var pvar:Null<String> = switch (patX) { case PVar(nm3): nm3; default: null; };
                                        var rIsBinder2 = switch (r2.def) { case EVar(nm4) if (nm4 == replacementName): true; default: false; };
                                        if (pvar != null && rIsBinder2) { droppedAlias = pvar; continue; }
                                    default:
                                }
                                if (droppedAlias != null) s1 = replaceVarInExpr(s1, droppedAlias, replacementName);
                                newStmts.push(s1);
                            }

                            // Choose binder based on actual usage in the rewritten body
                            var bodyExpr: ElixirAST = (newStmts.length == 1)
                                ? newStmts[0]
                                : makeAST(EBlock(newStmts));
                            // Usage-driven fallback: if body still references exactly one undefined lower-case var,
                            // treat it as the element alias and rewrite to the binder name (replacementName).
                            function collectUsedVars(n: ElixirAST, out: Map<String,Bool>): Void {
                                if (n == null || n.def == null) return;
                switch (n.def) {
                    case EVar(v): out.set(v, true);
                    case EBlock(ss): for (x in ss) collectUsedVars(x, out);
                    case EDo(ss2): for (x in ss2) collectUsedVars(x, out);
                    case EIf(c,t,e): collectUsedVars(c, out); collectUsedVars(t, out); if (e != null) collectUsedVars(e, out);
                    case ECase(expr, cs): collectUsedVars(expr, out); for (c in cs) collectUsedVars(c.body, out);
                    case EBinary(_, l, r): collectUsedVars(l, out); collectUsedVars(r, out);
                    case EField(obj, _): collectUsedVars(obj, out);
                    case EMatch(_, rhs): collectUsedVars(rhs, out);
                    case ECall(tgt, _, argsC): if (tgt != null) collectUsedVars(tgt, out); for (a in argsC) collectUsedVars(a, out);
                    case ERemoteCall(tgt2, _, argsR): collectUsedVars(tgt2, out); for (a in argsR) collectUsedVars(a, out);
                    case EList(els): for (el in els) collectUsedVars(el, out);
                    case ETuple(els2): for (el in els2) collectUsedVars(el, out);
                    case EKeywordList(ps): for (p in ps) collectUsedVars(p.value, out);
                    case EStructUpdate(base, fs): collectUsedVars(base, out); for (f in fs) collectUsedVars(f.value, out);
                    default:
                }
            }
                            function collectPatternVars(p: EPattern, out: Map<String,Bool>): Void {
                                switch (p) {
                                    case PVar(nm): out.set(nm, true);
                                    case PTuple(elems): for (pe in elems) collectPatternVars(pe, out);
                                    case PAlias(varName, pattern): out.set(varName, true); collectPatternVars(pattern, out);
                                    case PList(ps): for (pe2 in ps) collectPatternVars(pe2, out);
                                    default:
                                }
                            }
                            function collectBoundVars(stmts2:Array<ElixirAST>): Map<String,Bool> {
                                var m = new Map<String,Bool>();
                                if (binderName != null) m.set(safeBinder(binderName), true);
                                for (sSt in stmts2) switch (sSt.def) {
                                    case EBinary(Match, lft, _): switch (lft.def) { case EVar(nv): m.set(nv, true); default: }
                                    case EMatch(patY, _): collectPatternVars(patY, m);
                                    case ECase(_, clauses): for (cl in clauses) collectPatternVars(cl.pattern, m);
                                    default:
                                }
                                return m;
                            }
            var used = new Map<String,Bool>();
            collectUsedVars(bodyExpr, used);
            var bound = collectBoundVars(newStmts);
            var free:Array<String> = [];
            for (k in used.keys()) if (!bound.exists(k)) free.push(k);
            // Prefer candidates that appear as receiver/arg or in interpolations
            function appearsAsReceiverOrArg(n: ElixirAST, name:String): Bool {
                var found = false;
                ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
                    if (found) return x;
                    switch (x.def) {
                        case EField({def: EVar(v)}, _ ) if (v == name): found = true; return x;
                        case ECall(_, _, argsC): for (a in argsC) switch (a.def) { case EVar(v2) if (v2 == name): found = true; default: } return x;
                        case ERemoteCall(tgt2, _, argsR):
                            switch (tgt2.def) { case EVar(v3) if (v3 == name): found = true; default: }
                            for (a in argsR) switch (a.def) { case EVar(v4) if (v4 == name): found = true; default: }
                            return x;
                        case EString(str): if (str != null && (str.indexOf("#{" + name + "}") != -1 || str.indexOf("#{" + name + ".") != -1)) found = true; return x;
                        default: return x;
                    }
                });
                return found;
            }
            var eligible:Array<String> = [];
            for (nm in free) if (appearsAsReceiverOrArg(bodyExpr, nm)) eligible.push(nm);
            var didReplace = false;
            if (eligible.length == 1) {
                var aliasName = eligible[0];
                bodyExpr = replaceVarInExpr(bodyExpr, aliasName, replacementName);
                didReplace = true;
            } else if (free.length == 1) {
                var aliasName2 = free[0];
                bodyExpr = replaceVarInExpr(bodyExpr, aliasName2, replacementName);
                didReplace = true;
            } else if (free.length > 0) {
                // Conservative fallback: pick the first free lower-case name
                var aliasName3 = free[0];
                bodyExpr = replaceVarInExpr(bodyExpr, aliasName3, replacementName);
                didReplace = true;
            }
                            // If alias was dropped or free-var replaced, body will reference replacementName now
            var finalBinder: EPattern = (didReplace || bodyUsesVar(bodyExpr, replacementName))
                ? PVar(replacementName)
                : PWildcard;
                            var newFn = makeAST(EFn([{ args: [finalBinder], guard: clause.guard, body: bodyExpr }]));
                            makeASTWithMeta(ERemoteCall(mod, func, [listExpr, newFn]), node.metadata, node.pos);
                        default:
                            node;
                    }
                default:
                    node;
            }
        });
    }

    /**
     * Enum Each Sentinel Cleanup Pass
     * Remove bare 1/0 literals inside Enum.each anonymous function bodies.
     */
    public static function enumEachSentinelCleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, "each", args) if (args != null && args.length == 2):
                    switch (mod.def) {
                        case EVar(mn) if (mn == "Enum"):
                            var listExpr = args[0];
                            var fnArg = args[1];
                            switch (fnArg.def) {
                                case EFn(clauses) if (clauses.length == 1):
                                    var cl = clauses[0];
                                    var cleanedBody = switch (cl.body.def) {
                                        case EBlock(stmts):
                                            var out: Array<ElixirAST> = [];
                                            for (s in stmts) switch (s.def) {
                                                case EInteger(v) if (v == 0 || v == 1):
                                                case EFloat(f) if (f == 0.0):
                                                default: out.push(s);
                                            }
                                            makeASTWithMeta(EBlock(out), cl.body.metadata, cl.body.pos);
                                        /**
                                         * EDo support
                                         * - Handle do/end bodies by filtering out numeric sentinel-only statements.
                                         */
                                        case EDo(stmts2):
                                            var out2: Array<ElixirAST> = [];
                                            for (s in stmts2) switch (s.def) {
                                                case EInteger(v2) if (v2 == 0 || v2 == 1):
                                                case EFloat(f2) if (f2 == 0.0):
                                                default: out2.push(s);
                                            }
                                            makeASTWithMeta(EDo(out2), cl.body.metadata, cl.body.pos);
                                        default:
                                            cl.body;
                                    };
                                    // If binder is unused after cleanup, set wildcard
                                    var arg0 = cl.args.length > 0 ? cl.args[0] : PWildcard;
                                    var finalArg = switch (arg0) { case PVar(nm): (bodyUsesVar(cleanedBody, nm) ? arg0 : PWildcard); default: arg0; };
                                    var newFn = makeAST(EFn([{ args: [finalArg], guard: cl.guard, body: cleanedBody }]));
                                    makeASTWithMeta(ERemoteCall(mod, "each", [listExpr, newFn]), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    /**
     * Fn Arg Body Reference Normalize Pass
     *
     * WHAT: Within anonymous functions, normalize body references of underscored variants to the declared non-underscored binder.
     * WHY: Rewrites like Enum.find can switch binder to non-underscore while predicates still reference _name.
     */
    public static function fnArgBodyRefNormalizePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var body = cl.body;
                        var args = cl.args;
                        // Operate on first binder when present (works for single-arg and reduce two-arg forms)
                        if (args.length >= 1) {
                            switch (args[0]) {
                                case PVar(name) if (name != null && name.length > 0 && name.charAt(0) != '_'):
                                    // Body may still reference _name from earlier passes; normalize to name
                                    var underscore = "_" + name;
                                    var fixed = replaceVarInExpr(body, underscore, name);
                                    // Also normalize any occurrences in the presence of a second accumulator arg
                                    if (args.length >= 2) {
                                        switch (args[1]) {
                                            case PVar(accName) if (accName != null && accName.length > 0 && accName.charAt(0) != '_'):
                                                fixed = replaceVarInExpr(fixed, "_" + accName, accName);
                                            default:
                                        }
                                    }
                                    newClauses.push({args: args, guard: cl.guard, body: fixed});
                                case PVar(name) if (name != null && name.length > 1 && name.charAt(0) == '_'):
                                    // If underscored binder is actually referenced, rename binder to trimmed and rewrite body references
                                    if (bodyUsesVar(body, name)) {
                                        var trimmed = name.substr(1);
                                        var fixedBody = replaceVarInExpr(body, name, trimmed);
                                        newClauses.push({args: [PVar(trimmed)], guard: cl.guard, body: fixedBody});
                                    } else {
                                        newClauses.push(cl);
                                    }
                                default:
                                    newClauses.push(cl);
                            }
                            // If we have two-arg reduce form, also ensure body references align to provided arg names
                            if (args.length >= 2) {
                                var a0 = switch (args[0]) { case PVar(nm): nm; default: null; };
                                var a1 = switch (args[1]) { case PVar(nm2): nm2; default: null; };
                                if (a0 != null && a0.length > 0) {
                                    var body2 = replaceVarInExpr(newClauses[newClauses.length - 1].body, "_" + a0, a0);
                                    if (a1 != null && a1.length > 0) body2 = replaceVarInExpr(body2, "_" + a1, a1);
                                    var last = newClauses.pop();
                                    newClauses.push({args: last.args, guard: last.guard, body: body2});
                                }
                            }
                        } else {
                            newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * Enum Each Head Extraction Pass
     *
     * WHAT
     * - Inside Enum.each(list, fn _ -> ... end) bodies, replace "tmp = list[0]" style
     *   head extraction with direct use of the anonymous function binder, and drop
     *   stray numeric sentinels (1/0) introduced by loop lowering.
     *
     * WHY
     * - Prevents warnings like "code block contains unused literal 1" and removes
     *   infrastructure artifacts (list[0]) that obscure the actual element variable.
     * - Enables subsequent passes (count/map rewrites) to operate on clean predicates
     *   that reference the binder instead of ad-hoc temps.
     *
     * HOW
     * - For ERemoteCall(Enum, "each", [list, fn([PVar(binder)]) -> EBlock(stmts) end]):
     *   - If stmts contains assignment "var = list[0]", remove that assignment and
     *     replace all occurrences of Var(var) in the remaining statements with the binder.
     *   - Drop standalone numeric literals (EInteger(1|0), EFloat(0.0)) inside the body.
     */
    public static function enumEachHeadExtractionPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)):
                    var listExpr = args[0];
                    var fnNode = args[1];
                    switch (fnNode.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var clause = clauses[0];
                            var binderName: Null<String> = null;
                            switch (clause.args.length > 0 ? clause.args[0] : null) {
                                case PVar(n): binderName = n;
                                default:
                            }
                            // Allow wildcard binder; if body extracts head alias, synthesize binder name
                            // We'll detect alias below; if binderName is null, we can default to "elem"
                            var newStmts: Array<ElixirAST> = [];
                            var removedAlias: Null<String> = null;
                            var promoteFieldsList: Bool = false;
                            var stmts: Array<ElixirAST> = switch (clause.body.def) {
                                case EBlock(ss): ss;
                                default: [clause.body];
                            };
                            for (s in stmts) {
                                var matched = false;
                                switch (s.def) {
                                    case EBinary(Match, left, right):
                                        switch (left.def) {
                                            case EVar(aliasVar):
                                                if (isHeadAccessOf(right, listExpr)) {
                                                    removedAlias = aliasVar; matched = true;
                                                    // If right is Reflect.fields(listExpr)[0], mark to promote listExpr
                                                    switch (right.def) {
                                                        case EAccess(tgt, key) if (switch (tgt.def) { case ERemoteCall({def: EVar(mod)}, fn, args) if (mod == "Reflect" && fn == "fields" && args != null && args.length == 1 && astEquals(args[0], listExpr)): true; default: false; }):
                                                            promoteFieldsList = true;
                                                        default:
                                                    }
                                                }
                                            default:
                                        }
                                    case EMatch(pattern, right2):
                                        // Left is a pattern; match PVar(alias)
                                        switch (pattern) {
                                            case PVar(aliasVar2):
                                                if (isHeadAccessOf(right2, listExpr)) {
                                                    removedAlias = aliasVar2; matched = true;
                                                    // Detect Reflect.fields(listExpr)[0] on RHS
                                                    switch (right2.def) {
                                                        case EAccess(tgt2, key2) if (switch (tgt2.def) { case ERemoteCall({def: EVar(mod2)}, fn2, args2) if (mod2 == "Reflect" && fn2 == "fields" && args2 != null && args2.length == 1 && astEquals(args2[0], listExpr)): true; default: false; }):
                                                            promoteFieldsList = true;
                                                        default:
                                                    }
                                                }
                                            default:
                                        }
                                    default:
                                }
                                if (!matched) newStmts.push(s);
                            }
                            // If no binder provided (PWildcard), synthesize one when alias is present
                            if (binderName == null && removedAlias != null) binderName = "elem";
                            if (binderName == null) return node;
                            var rewritten: Array<ElixirAST> = [];
                            for (s in newStmts) {
                                var keep = switch (s.def) {
                                    case EInteger(v) if (v == 0 || v == 1): false;
                                    case EFloat(f) if (f == 0.0): false;
                                    default: true;
                                };
                                if (!keep) continue;
                                var s2 = if (removedAlias != null)
                                    replaceVarInExpr(s, removedAlias, binderName)
                                else s;
                                rewritten.push(s2);
                            }
                            /**
                             * Fallback Binder Rewrite (Head Extraction)
                             *
                             * WHAT
                             * - When no head alias was found, but the body references exactly one
                             *   lowercase local variable, rewrite that variable to the element binder.
                             *
                             * WHY
                             * - Alias pruning can leave a single local (e.g., `todo`) in closures, which
                             *   later passes expect to be the binder; rewriting prevents undefined locals.
                             *
                             * HOW
                             * - Collect lowercase-started local names (exclude binder/_binder/id).
                             * - If exactly one candidate remains, replace all occurrences with the binder.
                             */
                            // If we did not have a head alias but the body uses local names other
                            // than declared ones, rewrite those free lowercase locals to the binder.
                            if (removedAlias == null && binderName != null) {
                                var bodyForVars = (rewritten.length == 1) ? rewritten[0] : makeAST(EBlock(rewritten));
                                var varsUsed = collectVars(bodyForVars);
                                varsUsed.remove(binderName);
                                if (varsUsed.exists("_" + binderName)) varsUsed.remove("_" + binderName);
                                if (varsUsed.exists("id")) varsUsed.remove("id");
                                // Collect locally declared names (lhs of assignments) to avoid rewriting them
                                var declared = new Map<String, Bool>();
                                for (s in newStmts) switch (s.def) {
                                    case EBinary(Match, left, _): switch (left.def) { case EVar(n): declared.set(n, true); default: }
                                    case EMatch(pat, _): switch (pat) { case PVar(n2): declared.set(n2, true); default: }
                                    default:
                                }
                                // Rewrite any used lowercase local that is not declared to the binder
                                var tmp: Array<ElixirAST> = [];
                                for (s in rewritten) {
                                    var s2 = s;
                                    for (k in varsUsed.keys()) {
                                        if (!declared.exists(k)) s2 = replaceVarInExpr(s2, k, binderName);
                                    }
                                    tmp.push(s2);
                                }
                                rewritten = tmp;
                            }
                            var newBody = (rewritten.length == 1)
                                ? rewritten[0]
                                : makeAST(EBlock(rewritten));
                            // Choose wildcard binder if unused to avoid warnings
                            var finalBinderName = safeBinder(binderName);
                            var finalBinder: EPattern = bodyUsesVar(newBody, finalBinderName) ? PVar(finalBinderName) : PWildcard;
                            var newFn = makeAST(EFn([{ args: [finalBinder], guard: clause.guard, body: newBody }]));
                            if (promoteFieldsList) {
                                // Hoist fields = Map.keys(listExpr) and iterate Enum.each(fields, fn field -> ...)
                                var fieldsVar = "fields";
                                var fieldBinder = "field";
                                var assign = makeAST(EBinary(Match, makeAST(EVar(fieldsVar)), makeAST(ERemoteCall(makeAST(EVar("Map")), "keys", [listExpr]))));
                                var fn2 = makeAST(EFn([{ args: [PVar(fieldBinder)], guard: clause.guard, body: replaceVarInExpr(newBody, finalBinderName, fieldBinder) }]));
                                var eachCall = makeAST(ERemoteCall(mod, func, [makeAST(EVar(fieldsVar)), fn2]));
                                makeASTWithMeta(EBlock([assign, eachCall]), node.metadata, node.pos);
                            } else {
                                // If we detected Reflect.fields(listExpr)[0] aliasing, promote the each source minimally
                                var eachList = listExpr;
                                makeASTWithMeta(ERemoteCall(mod, func, [eachList, newFn]), node.metadata, node.pos);
                            }
                        default:
                            node;
                    }
                default:
                    node;
            }
        });
    }

    static inline function isEnumEach(mod: ElixirAST, func: String, args: Array<ElixirAST>): Bool {
        return switch (mod.def) {
            case EVar(name) if ((name == "Enum") && func == "each" && args != null && args.length == 2): true;
            default: false;
        };
    }

    static function isHeadAccessOf(expr: ElixirAST, listExpr: ElixirAST): Bool {
        return switch (expr.def) {
            case EAccess(target, key):
                var keyIsZero = switch (key.def) { case EInteger(v) if (v == 0): true; default: false; };
                if (!keyIsZero) return false;
                // Direct head: listExpr[0]
                if (astEquals(target, listExpr)) return true;
                // Reflect.fields(listExpr)[0]
                switch (target.def) {
                    case ERemoteCall({def: EVar(mod)}, func, args) if (mod == "Reflect" && func == "fields" && args != null && args.length == 1):
                        return astEquals(args[0], listExpr);
                    default:
                }
                false;
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
                case EString(str):
                    var s = str;
                    if (s != null && s.indexOf("#{") != -1) {
                        var needle1 = "#{" + from + "}";
                        var needle2 = "#{" + from + ".";
                        var repl1 = "#{" + to + "}";
                        var repl2 = "#{" + to + ".";
                        s = s.split(needle1).join(repl1);
                        s = s.split(needle2).join(repl2);
                    }
                    makeASTWithMeta(EString(s), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function replaceVarWithExpr(n: ElixirAST, from: String, toExpr: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(name) if (name == from): makeASTWithMeta(toExpr.def, x.metadata, x.pos);
                default: x;
            }
        });
    }

    /**
     * Count Rewrite Pass
     *
     * WHAT
     * - Rewrites accumulator-style counting loops into Enum.count(list, predicate).
     */
    public static function countRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts) if (stmts.length >= 3):
                    // Strict 3-statement form: count=0; <each>; count
                    if (stmts.length == 3) {
                        var cvar: Null<String> = null;
                        var listExpr0: Null<ElixirAST> = null;
                        var binder0: String = "_elem";
                        var pred0: Null<ElixirAST> = null;
                        // match count=0
                        switch (stmts[0].def) {
                            case EBinary(Match, leftX0, rhsX0):
                                switch (leftX0.def) { case EVar(nm0): cvar = (switch (rhsX0.def) { case EInteger(v0) if (v0 == 0): nm0; default: null; }); default: }
                            case EMatch(pat0, rhs0):
                                switch (pat0) { case PVar(nm0b): cvar = (switch (rhs0.def) { case EInteger(v0b) if (v0b == 0): nm0b; default: null; }); default: }
                            default:
                        }
                        // match each
                        var eachExpr0: Null<ElixirAST> = null;
                        switch (stmts[1].def) {
                            case ERemoteCall(mod0, func0, args0) if (isEnumEach(mod0, func0, args0) && args0.length == 2): eachExpr0 = stmts[1];
                            case EMatch(_, rhsM0): switch (rhsM0.def) { case ERemoteCall(mod1, func1, args1) if (isEnumEach(mod1, func1, args1) && args1.length == 2): eachExpr0 = rhsM0; default: }
                            case EBinary(Match, _, rhsB0): switch (rhsB0.def) { case ERemoteCall(mod2, func2, args2) if (isEnumEach(mod2, func2, args2) && args2.length == 2): eachExpr0 = rhsB0; default: }
                            default:
                                // Handle tuple-pattern match represented as EBinary(Match, ETuple(...), rhs)
                                eachExpr0 = null;
                        }
                        if (cvar != null && eachExpr0 != null) {
                            switch (eachExpr0.def) {
                                case ERemoteCall(_m0, _f0, argsE):
                                    listExpr0 = argsE[0];
                                    switch (argsE[1].def) {
                                        case EFn(clauses0) if (clauses0.length == 1):
                                            var cl0 = clauses0[0];
                                            switch (cl0.args.length > 0 ? cl0.args[0] : null) { case PVar(n0): binder0 = n0; default: }
                                            var body0: Array<ElixirAST> = switch (cl0.body.def) { case EBlock(ss0): ss0; default: [cl0.body]; };
                                            var alias0: Null<String> = null;
                                            for (bs0 in body0) switch (bs0.def) {
                                                case EBinary(Match, lA0, rA0): switch (lA0.def) { case EVar(an0): if (isHeadAccessOf(rA0, listExpr0)) alias0 = an0; default: }
                                                case EMatch(patA0, rA1): switch (patA0) { case PVar(an1): if (isHeadAccessOf(rA1, listExpr0)) alias0 = an1; default: }
                                                case EIf(cond0, then0, _):
                                                    // Strict pattern: we treat the if condition as predicate regardless of inner assignment shape
                                                    if (pred0 == null) pred0 = cond0;
                                                default:
                                            }
                                            // After scan, if alias detected and predicate found using alias name, normalize it to binder
                                            if (alias0 != null && pred0 != null) {
                                                pred0 = replaceVarInExpr(pred0, alias0, binder0);
                                            }
                                            // Ensure any remaining field access on a local alias is switched to binder
                                            if (pred0 != null) {
                                                pred0 = normalizePredicateToBinder(pred0, binder0);
                                            }
                                        default:
                                    }
                                default:
                            }
                        }
                        // match return count
                        var returns0 = switch (stmts[2].def) { case EVar(nr0) if (cvar != null && nr0 == cvar): true; default: false; };
                        if (returns0 && listExpr0 != null && pred0 != null) {
                            var adjusted0 = safeBinder(binder0);
                            pred0 = replaceVarInExpr(pred0, binder0, adjusted0);
                            pred0 = replaceVarInExpr(pred0, "_" + adjusted0, adjusted0);
                            pred0 = normalizePredicateToBinder(pred0, adjusted0);
                            var fn0 = makeAST(EFn([{ args: [PVar(adjusted0)], guard: null, body: pred0 }]));
                            var new0 = makeAST(ERemoteCall(makeAST(EVar("Enum")), "count", [listExpr0, fn0]));
                            return makeASTWithMeta(new0.def, node.metadata, node.pos);
                        }
                    }
                    var countVar: Null<String> = null;
                    var listExpr: Null<ElixirAST> = null;
                    var binderName: String = "_elem";
                    var predicate: Null<ElixirAST> = null;
                    for (i in 0...stmts.length) switch (stmts[i].def) {
                        case EBinary(Match, left0, rhs):
                            switch (left0.def) {
                                case EVar(name):
                                    switch (rhs.def) { case EInteger(v) if (v == 0): countVar = name; default: }
                                default:
                            }
                        default:
                    }
                    if (countVar == null) return node;
                    for (i in 0...stmts.length) {
                        // Handle direct Enum.each(...) or wrapped in assignment/match
                        var eachCall: Null<ElixirAST> = null;
                        var aliasFromHead: Null<String> = null;
                        switch (stmts[i].def) {
                            case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args) && args.length == 2):
                                eachCall = stmts[i];
                            case EMatch(_, rhs):
                                switch (rhs.def) { case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args) && args.length == 2): eachCall = rhs; default: }
                            case EBinary(Match, _, rhs2):
                                switch (rhs2.def) { case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args) && args.length == 2): eachCall = rhs2; default: }
                            default:
                        }
                        if (eachCall != null) {
                            // extract list and binder/cond
                            switch (eachCall.def) {
                                case ERemoteCall(mod, func, args):
                                    listExpr = args[0];
                                    switch (args[1].def) {
                                        case EFn(clauses) if (clauses.length == 1):
                                            var cl = clauses[0];
                                            switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): binderName = n; default: }
                                            var bodyStmts: Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                                            for (bs in bodyStmts) switch (bs.def) {
                                                case EBinary(Match, leftAlias, rightAlias):
                                                    // Detect alias = list[0]
                                                    switch (leftAlias.def) { case EVar(an): if (isHeadAccessOf(rightAlias, listExpr)) aliasFromHead = an; default: }
                                                case EMatch(patAlias, rightAlias2):
                                                    switch (patAlias) { case PVar(an2): if (isHeadAccessOf(rightAlias2, listExpr)) aliasFromHead = an2; default: }
                                                case EIf(cond, thenBr, _):
                                                    var inc = false;
                                                    switch (thenBr.def) {
                                                        case EBlock(ts): for (t in ts) if (isCountIncrement(t, countVar)) { inc = true; break; }
                                                        default: if (isCountIncrement(thenBr, countVar)) inc = true;
                                                    }
                                                    if (inc) {
                                                        // If we detected aliasVar = head earlier, rewrite predicate to binder
                                                        var adjusted = if (aliasFromHead != null) replaceVarInExpr(cond, aliasFromHead, binderName) else cond;
                                                        // If unchanged, attempt shape-based rewrite (field compare)
                                                        if (ElixirASTPrinter.print(adjusted, 0) == ElixirASTPrinter.print(cond, 0)) {
                                                            switch (cond.def) {
                                                                case EBinary(Equal, l2, r2):
                                                                    switch (l2.def) {
                                                                        case EField(objL, fieldL):
                                                                            switch (objL.def) { case EVar(_): adjusted = makeAST(EBinary(Equal, makeAST(EField(makeAST(EVar(binderName)), fieldL)), r2)); default: }
                                                                        default:
                                                                    }
                                                                    switch (r2.def) {
                                                                        case EField(objR, fieldR):
                                                                            switch (objR.def) { case EVar(_): adjusted = makeAST(EBinary(Equal, l2, makeAST(EField(makeAST(EVar(binderName)), fieldR)))); default: }
                                                                        default:
                                                                    }
                                                                default:
                                                            }
                                                        }
                                                        predicate = adjusted;
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        }
                    }
                    if (predicate == null || listExpr == null) return node;
                    var lastExpr = stmts[stmts.length - 1];
                    var returnsCount = switch (lastExpr.def) { case EVar(n) if (n == countVar): true; default: false; };
                    if (!returnsCount) return node;
                    var adjustedBinder2 = safeBinder(binderName);
                    predicate = replaceVarInExpr(predicate, binderName, adjustedBinder2);
                    predicate = replaceVarInExpr(predicate, "_" + adjustedBinder2, adjustedBinder2);
                    var fnNode = makeAST(EFn([{ args: [PVar(adjustedBinder2)], guard: null, body: predicate }]));
                    var newCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "count", [listExpr, fnNode]));
                    makeASTWithMeta(newCall.def, node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function isCountIncrement(n: ElixirAST, countVar: String): Bool {
        return switch (n.def) {
            case EBinary(Match, left1, rhs):
                var lhsName: Null<String> = switch (left1.def) { case EVar(nm): nm; default: null; };
                if (lhsName != countVar) return false;
                switch (rhs.def) {
                    case EBinary(Add, l, r):
                        switch (l.def) { case EVar(n2) if (n2 == countVar):
                            switch (r.def) { case EInteger(v) if (v == 1): true; default: false; } default: false; }
                    default: false;
                }
            case EMatch(pat, expr):
                // Pattern match variant: count = count + 1
                var lhsName2: Null<String> = switch (pat) { case PVar(nm2): nm2; default: null; };
                if (lhsName2 != countVar) return false;
                switch (expr.def) {
                    case EBinary(Add, l2, r2):
                        switch (l2.def) { case EVar(n3) if (n3 == countVar):
                            switch (r2.def) { case EInteger(v2) if (v2 == 1): true; default: false; } default: false; }
                    default: false;
                }
            default: false;
        };
    }

    /**
     * Map+Join Rewrite Pass
     *
     * WHAT
     * - Collapses accumulator-style building of a list via Enum.each + Enum.concat followed
     *   by Enum.join(temp, sep) into a single Enum.map(list, fn -> item end) |> Enum.join(sep).
     */
    public static function mapJoinRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts) if (stmts.length >= 3):
                    var tempVar: Null<String> = null;
                    var initIdx = -1;
                    var listExpr: Null<ElixirAST> = null;
                    var binderName: String = "_elem";
                    var mapExpr: Null<ElixirAST> = null;
                    var aliasLocal: Null<String> = null;
                    var sep: Null<ElixirAST> = null;
                    // Find any `temp = []` initialization in the block
                    for (idx in 0...stmts.length) switch (stmts[idx].def) {
                        case EBinary(Match, leftInit, rhs):
                            switch (leftInit.def) {
                                case EVar(name):
                                    switch (rhs.def) { case EList(_): tempVar = name; initIdx = idx; default: }
                                default:
                            }
                        case EMatch(patInit, rhsInit):
                            switch (patInit) {
                                case PVar(name2):
                                    switch (rhsInit.def) { case EList(_): tempVar = name2; initIdx = idx; default: }
                                default:
                            }
                        default:
                    }
                    if (tempVar == null || initIdx == -1) return node;
                    // Enum.each with temp = Enum.concat(temp, [expr])
                    for (i in (initIdx+1)...stmts.length) {
                        var eachStmt: Null<ElixirAST> = null;
                        switch (stmts[i].def) {
                            case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)):
                                eachStmt = stmts[i];
                            case EMatch(_, rhs):
                                switch (rhs.def) { case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)): eachStmt = rhs; default: }
                            case EBinary(Match, _, rhs2):
                                switch (rhs2.def) { case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)): eachStmt = rhs2; default: }
                            default:
                        }
                        if (eachStmt != null) {
                            switch (eachStmt.def) {
                                case ERemoteCall(mod, func, args):
                                    listExpr = args[0];
                                    switch (args[1].def) {
                                        case EFn(clauses) if (clauses.length == 1):
                                            var cl = clauses[0];
                                            switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): binderName = n; default: }
                                    var bodyStmts: Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                                    for (bs in bodyStmts) switch (bs.def) {
                                        case EBinary(Match, leftAlias, rightAlias):
                                            switch (leftAlias.def) { case EVar(an): if (isHeadAccessOf(rightAlias, listExpr)) aliasLocal = an; default: }
                                        case EMatch(patAlias, rightAlias2):
                                            switch (patAlias) { case PVar(an2): if (isHeadAccessOf(rightAlias2, listExpr)) aliasLocal = an2; default: }
                                        case EBinary(Match, leftX, rhs) :
                                            var lhsTemp: Null<String> = switch (leftX.def) { case EVar(nx): nx; default: null; };
                                            if (lhsTemp != tempVar) {
                                                // not our accumulator assignment
                                            } else {
                                                switch (rhs.def) {
                                                    case ERemoteCall(mod2, "concat", concatArgs) if (concatArgs.length == 2):
                                                        // Ensure module is Enum
                                                        switch (mod2.def) {
                                                            case EVar(mn) if (mn == "Enum"):
                                                                var isSelf = switch (concatArgs[0].def) { case EVar(n2) if (n2 == tempVar): true; default: false; };
                                                                var exprInside: Null<ElixirAST> = null;
                                                                switch (concatArgs[1].def) { case EList(items) if (items.length == 1): exprInside = items[0]; default: }
                                                    if (isSelf && exprInside != null) {
                                                        mapExpr = exprInside;
                                                        if (aliasLocal != null) mapExpr = replaceVarInExpr(mapExpr, aliasLocal, binderName);
                                                    }
                                                            default:
                                                    }
                                                case EMatch(patX, rhsP):
                                                    // Pattern match variant: tempVar = Enum.concat(...)
                                                    var lhsTemp2: Null<String> = switch (patX) { case PVar(nx2): nx2; default: null; };
                                                    if (lhsTemp2 == tempVar) {
                                                        switch (rhsP.def) {
                                                            case ERemoteCall(mod2b, "concat", concatArgs2) if (concatArgs2.length == 2):
                                                                switch (mod2b.def) {
                                                                    case EVar(mnb) if (mnb == "Enum"):
                                                                        var isSelf2 = switch (concatArgs2[0].def) { case EVar(n2b) if (n2b == tempVar): true; default: false; };
                                                                        var exprInside2: Null<ElixirAST> = null;
                                                                        switch (concatArgs2[1].def) { case EList(items2) if (items2.length == 1): exprInside2 = items2[0]; default: }
                                                                        if (isSelf2 && exprInside2 != null) mapExpr = exprInside2;
                                                                    default:
                                                                }
                                                            default:
                                                        }
                                                    }
                                                default:
                                            }
                                            }
                                        default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        }
                    }
                    if (listExpr == null || mapExpr == null) return node;
                    // Enum.join(temp, sep)
                    var finalExpr = stmts[stmts.length - 1];
                    switch (finalExpr.def) {
                        case ERemoteCall(mod3, "join", jArgs) if (jArgs.length == 2):
                            switch (mod3.def) {
                                case EVar(mn3) if (mn3 == "Enum"):
                                    switch (jArgs[0].def) { case EVar(n3) if (n3 == tempVar): sep = jArgs[1]; default: }
                                default:
                            }
                        default:
                    }
                    if (sep == null) return node;
                    var adjustedBinder3 = safeBinder(binderName);
                    mapExpr = replaceVarInExpr(mapExpr, binderName, adjustedBinder3);
                    mapExpr = replaceVarInExpr(mapExpr, "_" + adjustedBinder3, adjustedBinder3);
                    var fnNode = makeAST(EFn([{ args: [PVar(adjustedBinder3)], guard: null, body: mapExpr }]));
                    var mapCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "map", [listExpr, fnNode]));
                    var joinCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [mapCall, sep]));
                    makeASTWithMeta(joinCall.def, node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    /**
     * Map Concat-Each → Direct Map Assignment Pass
     *
     * WHAT
     * - Rewrites patterns of the form:
     *     temp = []
     *     Enum.each(list, fn binder -> temp = Enum.concat(temp, [expr]) end)
     *     ... (later uses temp)
     *   into:
     *     temp = Enum.map(list, fn binder -> expr end)
     *
     * WHY
     * - Eliminates closure-local rebind warnings and sentinel literals; produces
     *   idiomatic accumulation without changing semantics.
     */
    public static function mapConcatEachToMapAssignPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts) if (stmts.length >= 2):
                    var temp:Null<String> = null;
                    var initIdx = -1;
                    for (i in 0...stmts.length) switch (stmts[i].def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) { case EVar(n): switch (rhs.def) { case EList(_): temp = n; initIdx = i; default: } default: }
                        case EMatch(pat, rhs2):
                            switch (pat) { case PVar(n2): switch (rhs2.def) { case EList(_): temp = n2; initIdx = i; default: } default: }
                        default:
                    }
                    if (temp == null) return node;
                    var listExpr:Null<ElixirAST> = null;
                    var binderName:String = "_elem";
                    var exprInside:Null<ElixirAST> = null;
                    var eachIdx = -1;
                    for (i in initIdx+1...stmts.length) switch (stmts[i].def) {
                        case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)):
                            listExpr = args[0]; eachIdx = i;
                            switch (args[1].def) {
                                case EFn(clauses) if (clauses.length == 1):
                                    var cl = clauses[0];
                                    switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): binderName = n; default: }
                                    var bodyStmts = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                                    for (bs in bodyStmts) switch (bs.def) {
                                        case EBinary(Match, leftX, rhsX):
                                            var lhsName:Null<String> = switch (leftX.def) { case EVar(nm): nm; default: null; };
                                            if (lhsName == temp) switch (rhsX.def) {
                                                case ERemoteCall({def: EVar(mn)}, "concat", cargs) if (mn == "Enum" && cargs.length == 2):
                                                    switch (cargs[0].def) { case EVar(nv) if (nv == temp): switch (cargs[1].def) { case EList(items) if (items.length == 1): exprInside = items[0]; default: } default: }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                    if (listExpr == null || exprInside == null || eachIdx == -1) return node;
                    var adjusted = safeBinder(binderName);
                    exprInside = replaceVarInExpr(exprInside, binderName, adjusted);
                    exprInside = replaceVarInExpr(exprInside, "_" + adjusted, adjusted);
                    var fn = makeAST(EFn([{ args: [PVar(adjusted)], guard: null, body: exprInside }]));
                    var mapCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "map", [listExpr, fn]));
                    var newStmts:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        if (i == initIdx) {
                            // Replace init with assignment to mapCall
                            newStmts.push(makeAST(EBinary(Match, makeAST(EVar(temp)), mapCall)));
                        } else if (i == eachIdx) {
                            // Drop the Enum.each statement
                        } else newStmts.push(stmts[i]);
                    }
                    makeASTWithMeta(EBlock(newStmts), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    /**
     * Concat-Each → Reduce (Conditional Append) Pass
     *
     * WHAT
     * - Rewrites patterns of the form:
     *     temp = []
     *     Enum.each(list, fn binder ->
     *       ... (nested/guarded) ...
     *       if cond do
     *         temp = Enum.concat(temp, [expr])  # or temp = temp ++ [expr]
     *       end
     *     end)
     *     temp
     *   into:
     *     Enum.reduce(list, [], fn binder, acc ->
     *       if cond, do: acc ++ [expr], else: acc
     *     end)
     *
     * WHY
     * - Handles guarded/nested closures where a simple map rewrite is not correct.
     * - Eliminates closure-local rebind warnings and produces idiomatic accumulation.
     */
    public static function concatEachToReducePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts) if (stmts.length >= 3):
                    var temp:Null<String> = null;
                    var initIdx = -1;
                    for (i in 0...stmts.length) switch (stmts[i].def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) { case EVar(n): switch (rhs.def) { case EList(items) if (items.length == 0): temp = n; initIdx = i; default: } default: }
                        case EMatch(pat, rhs2):
                            switch (pat) { case PVar(n2): switch (rhs2.def) { case EList(items2) if (items2.length == 0): temp = n2; initIdx = i; default: } default: }
                        default:
                    }
                    if (temp == null) return node;

                    // Find Enum.each
                    var eachIdx = -1;
                    var listExpr: Null<ElixirAST> = null;
                    var clause: Null<{args:Array<EPattern>, body:ElixirAST, guard:Null<ElixirAST>}> = null;
                    for (i in initIdx+1...stmts.length) switch (stmts[i].def) {
                        case ERemoteCall(mod, func, args) if (func == "each" && args.length == 2):
                            switch (mod.def) { case EVar(m) if (m == "Enum"): listExpr = args[0];
                                switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): clause = clauses[0]; eachIdx = i; default: } default: }
                        case EBinary(Match, _, rhs) | EMatch(_, rhs):
                            switch (rhs.def) { case ERemoteCall(mod2, func2, args2) if (func2 == "each" && args2.length == 2):
                                switch (mod2.def) { case EVar(m2) if (m2 == "Enum"): listExpr = args2[0];
                                    switch (args2[1].def) { case EFn(clauses2) if (clauses2.length == 1): clause = clauses2[0]; eachIdx = i; default: } default: } default: }
                        default:
                    }
                    if (eachIdx == -1 || listExpr == null || clause == null) return node;

                    // Final statement must return temp
                    var returnsTemp = switch (stmts[stmts.length - 1].def) { case EVar(vn) if (vn == temp): true; default: false; };
                    if (!returnsTemp) return node;

                    // Find at least one conditional append inside fn body
                    var binder: String = switch (clause.args.length > 0 ? clause.args[0] : null) { case PVar(n): n; default: "elem"; };
                    var bodyStmts: Array<ElixirAST> = switch (clause.body.def) { case EBlock(ss): ss; default: [clause.body]; };

                    // Presence-like shape detection and cleanup: drop
                    //   user_id = Reflect.fields(listExpr)[0]
                    //   entry = Map.get(listExpr, user_id)
                    // and use binder instead of local alias
                    var localEntryAlias: Null<String> = null;
                    var cleanedStmts: Array<ElixirAST> = [];
                    var presenceShape = false;
                    var presenceUsesMetas = false; // guard to ensure we only treat true Presence entries
                    for (bs in bodyStmts) {
                        var drop = false;
                        switch (bs.def) {
                            case EBinary(Match, left, right):
                                // a = Reflect.fields(listExpr)[0]
                                switch (right.def) {
                                    case EAccess(tgt, _):
                                        switch (tgt.def) {
                                            case ERemoteCall({def: EVar("Reflect")}, "fields", [arg]) if (ElixirASTPrinter.print(arg, 0) == ElixirASTPrinter.print(listExpr, 0)):
                                                drop = true; presenceShape = true;
                                            default:
                                        }
                                    default:
                                }
                                if (!drop) switch (left.def) {
                                    case EVar(aliasName):
                                        // alias = Map.get(listExpr, key)
                                        switch (right.def) {
                                            case ERemoteCall({def: EVar("Map")}, "get", [m, _key]) if (ElixirASTPrinter.print(m, 0) == ElixirASTPrinter.print(listExpr, 0)):
                                                localEntryAlias = aliasName; drop = true; presenceShape = true;
                                            default:
                                        }
                                    default:
                                }
                                // Detect typical Presence entry usage: <entry>.metas or <binder>.metas
                                switch (right.def) {
                                    case EAccess(arrX, _):
                                        switch (arrX.def) {
                                            case EField(_, fieldX) if (fieldX == "metas"): presenceUsesMetas = true;
                                            default:
                                        }
                                    default:
                                }
                            case EMatch(pat, right2):
                                switch (right2.def) {
                                    case EAccess(tgt2, _):
                                        switch (tgt2.def) {
                                            case ERemoteCall({def: EVar("Reflect")}, "fields", [arg2]) if (ElixirASTPrinter.print(arg2, 0) == ElixirASTPrinter.print(listExpr, 0)):
                                                drop = true; presenceShape = true;
                                            default:
                                        }
                                    default:
                                }
                                if (!drop) switch (pat) {
                                    case PVar(aliasName2):
                                        switch (right2.def) {
                                            case ERemoteCall({def: EVar("Map")}, "get", [m2, _key2]) if (ElixirASTPrinter.print(m2, 0) == ElixirASTPrinter.print(listExpr, 0)):
                                                localEntryAlias = aliasName2; drop = true; presenceShape = true;
                                            default:
                                        }
                                    default:
                                }
                                // Detect <entry>.metas or binder.metas in pattern match contexts as well
                                switch (right2.def) {
                                    case EAccess(arrY, _):
                                        switch (arrY.def) {
                                            case EField(_, fieldY) if (fieldY == "metas"): presenceUsesMetas = true;
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!drop) cleanedStmts.push(bs);
                    }

                    // If presence-like shape detected AND presence metas are referenced,
                    // synthesize a presence-friendly reduce(Map.values(...))
                    if (presenceShape && presenceUsesMetas) {
                        var binderSafe = safeBinder(binder);
                        // Build meta expr and extract condition from branch that appends temp
                        var metaExpr = makeAST(EAccess(makeAST(EField(makeAST(EVar(binderSafe)), "metas")), makeAST(EInteger(0))));
                        var cond: Null<ElixirAST> = null;
                        // Find a condition in body that controls append of temp
                        function isTempAppendAssign(s:ElixirAST, name:String):Bool {
                            return switch (s.def) {
                                case EBinary(Match, left, rhs):
                                    switch (left.def) {
                                        case EVar(v) if (v == name):
                                            switch (rhs.def) {
                                                case ERemoteCall({def: EVar("Enum")}, "concat", [a0, _]):
                                                    switch (a0.def) { case EVar(v0) if (v0 == name): true; default: false; }
                                                case EBinary(Concat, llist, _):
                                                    switch (llist.def) { case EVar(v1) if (v1 == name): true; default: false; }
                                                default: false;
                                            }
                                        default: false;
                                    }
                                default: false;
                            };
                        }
                        function presenceAppendsTemp(expr:ElixirAST, name:String):Bool {
                            switch (expr?.def) {
                                case EBlock(ss): for (s in ss) if (isTempAppendAssign(s, name)) return true; return false;
                                default: return isTempAppendAssign(expr, name);
                            }
                        }
                        function findCond(nodes:Array<ElixirAST>):Null<ElixirAST> {
                            if (nodes == null) return null;
                            for (n in nodes) {
                                switch (n.def) {
                                    case EIf(c, t, e):
                                        // If then-branch appends temp, pick c
                                        if (presenceAppendsTemp(t, temp)) return c;
                                        var a = findCond(switch (t.def) { case EBlock(ss): ss; default: [t]; });
                                        if (a != null) return a;
                                        var b = findCond(switch (e?.def) { case EBlock(ss2): ss2; default: e != null ? [e] : []; });
                                        if (b != null) return b;
                                    default:
                                }
                            }
                            return null;
                        }
                        cond = findCond(bodyStmts);
                        // Normalize references in cond: local entry alias and meta alias to binder/metaExpr
                        if (localEntryAlias != null) cond = replaceVarInExpr(cond, localEntryAlias, binderSafe);
                        // Replace common names
                        cond = replaceVarInExpr(cond, "entry", binderSafe);
                        // Detect meta alias name and replace
                        var metaAlias: Null<String> = null;
                        for (bs in bodyStmts) switch (bs.def) {
                            case EBinary(Match, leftX, rightX):
                                switch (leftX.def) {
                                    case EVar(mn):
                                        switch (rightX.def) {
                                            case EAccess(arrX, _):
                                                switch (arrX.def) { case EField(_, fieldX) if (fieldX == "metas"): metaAlias = mn; default: }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        if (metaAlias != null) cond = replaceVarWithExpr(cond, metaAlias, metaExpr);

                        var appendMeta = makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([metaExpr]))));
                        var outerCond = makeAST(EBinary(Greater, makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [ makeAST(EField(makeAST(EVar(binderSafe)), "metas")) ])), makeAST(EInteger(0))));
                        var inner = (cond != null) ? makeAST(EIf(cond, appendMeta, makeAST(EVar("acc")))) : appendMeta;
                        var reducer = makeAST(EFn([{ args: [PVar(binderSafe), PVar("acc")], guard: clause.guard, body: makeAST(EIf(outerCond, inner, makeAST(EVar("acc")))) }]));
                        var reduceInput = makeAST(ERemoteCall(makeAST(EVar("Map")), "values", [listExpr]));
                        var reduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [reduceInput, makeAST(EList([])), reducer]));
                        var out2:Array<ElixirAST> = [];
                        for (i in 0...stmts.length) {
                            if (i == initIdx) out2.push(reduceCall) else if (i == eachIdx || i == stmts.length - 1) {} else out2.push(stmts[i]);
                        }
                        return makeASTWithMeta(EBlock(out2), node.metadata, node.pos);
                    }

                    // Apply alias replacement to cleaned statements when present
                    var normalizedStmts: Array<ElixirAST> = [];
                    for (cs in cleanedStmts) {
                        var cs2 = cs;
                        if (localEntryAlias != null) cs2 = replaceVarInExpr(cs2, localEntryAlias, binder);
                        normalizedStmts.push(cs2);
                    }

                    function rewriteAccAssign(s: ElixirAST): Null<ElixirAST> {
                        return switch (s.def) {
                            case EBinary(Match, left, rhs):
                                switch (left.def) {
                                    case EVar(lhs) if (lhs == temp):
                                        switch (rhs.def) {
                                            case ERemoteCall({def: EVar("Enum")}, "concat", [a0, a1]):
                                                switch (a0.def) {
                                                    case EVar(v0) if (v0 == temp):
                                                        switch (a1.def) { case EList(items) if (items.length == 1): makeAST(EBinary(Concat, makeAST(EVar("acc")), makeAST(EList([items[0]])))); default: null; }
                                                    default: null;
                                                }
                                            case EBinary(Concat, llist, rlist):
                                                switch (llist.def) { case EVar(v1) if (v1 == temp): makeAST(EBinary(Concat, makeAST(EVar("acc")), rlist)); default: null; }
                                            default: null;
                                        }
                                    default: null;
                                }
                            default: null;
                        };
                    }

                    // Construct reduced body: traverse guarded conditionals and rewrite rebinds to acc = acc ++ [expr]
                    function transformBody(expr: ElixirAST): ElixirAST {
                        if (expr == null) return makeAST(EVar("acc"));
                        return switch (expr.def) {
                            case EIf(cond, thenBr, elseBr):
                                // Try direct rewrite on original branches first
                                var directThenAppend = rewriteAccAssign(thenBr);
                                var directElseAppend = (elseBr == null) ? null : rewriteAccAssign(elseBr);
                                var thenX = (directThenAppend != null) ? directThenAppend : transformBody(thenBr);
                                var elseX = (elseBr == null) ? makeAST(EVar("acc")) : ((directElseAppend != null) ? directElseAppend : transformBody(elseBr));
                                // If a branch boils down to an append expression, emit conditional acc append; else keep shape
                                var thenAppend = rewriteAccAssign(thenX);
                                var elseAppend = rewriteAccAssign(elseX);
                                if (thenAppend != null && elseAppend == null) {
                                    // if cond do acc ++ [expr] else acc end
                                    makeAST(EIf(cond, thenAppend, makeAST(EVar("acc"))));
                                } else if (thenAppend != null && elseAppend != null) {
                                    // both sides append; keep original if; result expression is chosen by branch
                                    makeAST(EIf(cond, thenAppend, elseAppend));
                                } else {
                                    // keep structure but ensure branches produce accumulator
                                    var keptElse = (elseBr == null) ? makeAST(EVar("acc")) : transformBody(elseBr);
                                    makeAST(EIf(cond, transformBody(thenBr), keptElse));
                                }
                            case EBlock(ss):
                                var out:Array<ElixirAST> = [];
                                for (s in ss) {
                                    var r = transformBody(s);
                                    // Drop standalone sentinels
                                    switch (r.def) {
                                        case EInteger(v) if (v == 0 || v == 1):
                                        case EFloat(f) if (f == 0.0):
                                        default: out.push(r);
                                    }
                                }
                                makeAST(EBlock(out));
                            default:
                                expr;
                        };
                    }

                    // Rebuild a body AST from normalized statements
                    var bodyForTransform: ElixirAST = (normalizedStmts.length == 1) ? normalizedStmts[0] : makeAST(EBlock(normalizedStmts));
                    var rewrittenBody = transformBody(bodyForTransform);
                    // Ensure the final expression of the reducer returns acc
                    var reducerBody = switch (rewrittenBody.def) {
                        case EBlock(ss):
                            var needTail = true;
                            if (ss.length > 0) switch (ss[ss.length - 1].def) { case EVar(nm) if (nm == "acc"): needTail = false; default: }
                            makeAST(needTail ? EBlock(ss.concat([makeAST(EVar("acc"))])) : EBlock(ss));
                        default:
                            var lastIsAcc = switch (rewrittenBody.def) { case EVar(nm2) if (nm2 == "acc"): true; default: false; };
                            lastIsAcc ? rewrittenBody : makeAST(EBlock([rewrittenBody, makeAST(EVar("acc"))]));
                    };

                    // Final sanitation on reducer body:
                    // - Replace any lingering temp rebinds with acc-based concat
                    // - Replace local entry alias with binder if still present
                    reducerBody = ElixirASTTransformer.transformNode(reducerBody, function(t: ElixirAST): ElixirAST {
                        return switch (t.def) {
                            case EBinary(Match, leftT, rhsT):
                                switch (leftT.def) {
                                    case EVar(lhsT) if (lhsT == temp):
                                        // Normalize to acc = acc ++ [expr] when possible
                                        var repl = rewriteAccAssign(t);
                                        if (repl != null) makeASTWithMeta(EBinary(Match, makeAST(EVar("acc")), repl), t.metadata, t.pos) else t;
                                    default: t;
                                }
                            default: t;
                        };
                    });
                    if (localEntryAlias != null) reducerBody = replaceVarInExpr(reducerBody, localEntryAlias, binder);

                    var reducer = makeAST(EFn([{ args: [PVar(safeBinder(binder)), PVar("acc")], guard: clause.guard, body: reducerBody }]));
                    // If presence shape detected (with metas), prefer Map.values(listExpr)
                    var reduceInput = (presenceShape && presenceUsesMetas)
                        ? makeAST(ERemoteCall(makeAST(EVar("Map")), "values", [listExpr]))
                        : listExpr;
                    var reduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [reduceInput, makeAST(EList([])), reducer]));

                    // Emit new block: replace init with reduceCall; drop each and final temp
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        if (i == initIdx) {
                            // Replace init with reduce result; do not include original init
                            out.push(reduceCall);
                        } else if (i == eachIdx || i == stmts.length - 1) {
                            // drop Enum.each and final temp return
                        } else out.push(stmts[i]);
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);

                default:
                    node;
            }
        });
    }

    /**
     * Enum.each LHS Discard Pass
     *
     * WHAT
     * - Rewrites `{x} = Enum.each(list, fn -> ... end)` to `Enum.each(list, fn -> ... end)`
     *   when the LHS is a tuple pattern used only to bind the return value (unused).
     */
    public static function enumEachLhsDiscardPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EMatch(pat, rhs):
                                var isTuple = switch (pat) { case PTuple(_): true; default: false; };
                                switch (rhs.def) {
                                    case ERemoteCall(mod, func, args) if (isTuple && isEnumEach(mod, func, args)):
                                        out.push(makeASTWithMeta(ERemoteCall(mod, func, args), s.metadata, s.pos));
                                    default:
                                        out.push(s);
                                }
                            case EBinary(Match, left, rhs2):
                                var isTuple2 = switch (left.def) { case ETuple(_): true; default: false; };
                                switch (rhs2.def) {
                                    case ERemoteCall(mod2, func2, args2) if (isTuple2 && isEnumEach(mod2, func2, args2)):
                                        out.push(makeASTWithMeta(ERemoteCall(mod2, func2, args2), s.metadata, s.pos));
                                    default:
                                        out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    /**
     * Count Binder Normalize Pass
     *
     * WHAT
     * - For Enum.count(list, fn _x -> ... end) where the binder starts with underscore
     *   and is referenced in the body, rename binder to its trimmed variant and rewrite
     *   body references accordingly to avoid underscore-used warnings.
     */
    public static function countBinderNormalizePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar(m)}, "count", [list, fnExpr]) if (m == "Enum"):
                    switch (fnExpr.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var cl = clauses[0];
                            if (cl.args.length == 1) {
                                switch (cl.args[0]) {
                                    case PVar(name) if (name != null && name.length > 0):
                                        var trimmed = safeBinder(name);
                                        var newBody = cl.body;
                                        // Rewrite body refs: _trimmed -> trimmed
                                        newBody = replaceVarInExpr(newBody, "_" + trimmed, trimmed);
                                        // If binder itself is underscored, also rewrite binder refs to trimmed
                                        if (name != trimmed) newBody = replaceVarInExpr(newBody, name, trimmed);
                                        #if debug_hygiene
                                        trace('[CountBinderNormalize] binder=' + name + ' trimmed=' + trimmed + ' rewrote body in Enum.count');
                                        #end
                                        var newFn = makeAST(EFn([{ args: [PVar(trimmed)], guard: cl.guard, body: newBody }]));
                                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "count", [list, newFn]), n.metadata, n.pos);
                                    default:
                                        n;
                                }
                            } else n;
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    /**
     * Find Rewrite Pass
     *
     * WHAT
     * - Rewrites Enum.each scans that return nil afterwards into Enum.find(list, &pred/1).
     *
     * WHY
     * - Eliminates non-idiomatic scans with sentinel artifacts and final nil.
     *
     * HOW
     * - Detect EBlock([... EMatch/EBinary(Match) = Enum.each(list, fn binder -> if cond, do: value end) ..., ENil])
     * - Replace with Enum.find(list, fn binder -> cond end)
     */
    public static function findRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts) if (stmts.length >= 2):
                    // Must end with nil (explicitly)
                    var lastIsNil = switch (stmts[stmts.length - 1].def) { case ENil: true; default: false; };
                    if (!lastIsNil) return node;

                    // Search for Enum.each as a statement (optionally assigned/matched)
                    var eachStmt: Null<ElixirAST> = null;
                    for (i in 0...stmts.length - 1) switch (stmts[i].def) {
                        case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args) && args.length == 2):
                            eachStmt = stmts[i];
                        case EMatch(_, rhs):
                            switch (rhs.def) { case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args) && args.length == 2): eachStmt = rhs; default: }
                        case EBinary(Match, _, rhs2):
                            switch (rhs2.def) { case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args) && args.length == 2): eachStmt = rhs2; default: }
                        default:
                    }
                    if (eachStmt == null) return node;

                    var listExpr: Null<ElixirAST> = null;
                    var binderName: String = "_elem";
                    var condExpr: Null<ElixirAST> = null;
                    var aliasFromHead: Null<String> = null;
                    switch (eachStmt.def) {
                        case ERemoteCall(_m, _f, args):
                            listExpr = args[0];
                            switch (args[1].def) {
                                case EFn(clauses) if (clauses.length == 1):
                                    var cl = clauses[0];
                                    switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): binderName = n; default: }
                                    var bodyStmts: Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                                    for (bs in bodyStmts) switch (bs.def) {
                                        case EBinary(Match, leftAlias, rightAlias):
                                            switch (leftAlias.def) { case EVar(an): if (isHeadAccessOf(rightAlias, listExpr)) aliasFromHead = an; default: }
                                        case EMatch(patAl, rightAl2):
                                            switch (patAl) { case PVar(an2): if (isHeadAccessOf(rightAl2, listExpr)) aliasFromHead = an2; default: }
                                        case EIf(cond, _thenBr, _elseBr):
                                            // Use the boolean condition for find/2
                                            condExpr = cond;
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                    if (listExpr == null || condExpr == null) return node;
                    // Prefer replacing alias detected from head extraction; otherwise, if
                    // predicate references exactly one non-binder local variable name, treat
                    // it as the alias and replace it with binder.
                    var pred: ElixirAST = null;
                    if (aliasFromHead != null) {
                        pred = replaceVarInExpr(condExpr, aliasFromHead, binderName);
                    } else {
                        var varsUsed = collectVars(condExpr);
                        // Drop binder and common closure vars like 'id'
                        varsUsed.remove(binderName);
                        if (varsUsed.exists("id")) varsUsed.remove("id");
                        // If exactly one candidate remains, rewrite it to binder
                        var candidates = [for (k in varsUsed.keys()) k];
                        if (candidates.length == 1) {
                            pred = replaceVarInExpr(condExpr, candidates[0], binderName);
                        } else {
                            pred = condExpr;
                        }
                    }
                    // If no replacement happened, try shape-based rewrite of field compare
                    if (ElixirASTPrinter.print(pred, 0) == ElixirASTPrinter.print(condExpr, 0)) {
                        switch (condExpr.def) {
                            case EBinary(Equal, l, r):
                                switch (l.def) {
                                    case EField(obj, fieldName):
                                        switch (obj.def) { case EVar(_): pred = makeAST(EBinary(Equal, makeAST(EField(makeAST(EVar(binderName)), fieldName)), r)); default: }
                                    default:
                                }
                                switch (r.def) {
                                    case EField(obj2, fieldName2):
                                        switch (obj2.def) { case EVar(_): pred = makeAST(EBinary(Equal, l, makeAST(EField(makeAST(EVar(binderName)), fieldName2)))); default: }
                                    default:
                                }
                            default:
                        }
                    }
                    var adjustedBinder = safeBinder(binderName);
                    pred = replaceVarInExpr(pred, binderName, adjustedBinder);
                    pred = replaceVarInExpr(pred, "_" + adjustedBinder, adjustedBinder);
                    pred = normalizePredicateToBinder(pred, adjustedBinder);
                    var fnNode = makeAST(EFn([{ args: [PVar(adjustedBinder)], guard: null, body: pred }]));
                    var newCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "find", [listExpr, fnNode]));
                    makeASTWithMeta(newCall.def, node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function collectVars(node: ElixirAST): Map<String, Bool> {
        var used = new Map<String, Bool>();
        function visit(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EVar(name):
                    if (name != null && name.length > 0) {
                        var c = name.charAt(0);
                        if (c == c.toLowerCase()) used.set(name, true);
                    }
                case EField(target, _): visit(target);
                case EBinary(_, l, r): visit(l); visit(r);
                case EUnary(_, e): visit(e);
                case ECall(t, _, args): if (t != null) visit(t); for (a in args) visit(a);
                case ERemoteCall(t2, _, args2): visit(t2); for (a2 in args2) visit(a2);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case EBlock(ss): for (s in ss) visit(s);
                case ECase(expr, clauses): visit(expr); for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(node);
        return used;
    }

    static function normalizePredicateToBinder(node: ElixirAST, binder: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EField(target, field):
                    switch (target.def) {
                        case EVar(name) if (name != binder):
                            makeASTWithMeta(EField(makeAST(EVar(binder)), field), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function bodyUsesVar(body: ElixirAST, name: String): Bool {
        var used = false;
        function visit(n: ElixirAST): Void {
            if (used || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(nm) if (nm == name): used = true;
                case EField(target, _): visit(target);
                case EBlock(sts): for (s in sts) visit(s);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case EBinary(_, l, r): visit(l); visit(r);
                case EUnary(_, e1): visit(e1);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a in args2) visit(a);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                default:
            }
        }
        visit(body);
        return used;
    }
    
    /**
     * Map set-call rewrite pass
     * 
     * WHY: Some builders emit imperative map mutations like `g.set("key", value)` which
     *      are invalid in Elixir (variables are not modules). This rewrites them to
     *      `g = Map.put(g, :key, value)` so downstream passes (mapBuilderCollapsePass)
     *      can collapse to a literal map.
     */
    public static function mapSetRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(target, func, args) if (func == "set" && args != null && args.length == 2):
                    switch (target.def) {
                        case EVar(name):
                            var keyExpr = args[0];
                            // Convert string literal keys to atoms when possible
                            var atomKey: Null<ElixirAST> = switch (keyExpr.def) {
                                case EString(s): makeAST(EAtom(s));
                                default: null;
                            };
                            var finalKey = atomKey != null ? atomKey : keyExpr;
                            var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [makeAST(EVar(name)), finalKey, args[1]]));
                            makeAST(EMatch(PVar(name), putCall));
                        default:
                            n;
                    }
                case ECall(target, func, args) if (target != null && func == "set" && args != null && args.length == 2):
                    switch (target.def) {
                        case EVar(name):
                            var keyExpr = args[0];
                            var atomKey: Null<ElixirAST> = switch (keyExpr.def) {
                                case EString(s): makeAST(EAtom(s));
                                default: null;
                            };
                            var finalKey = atomKey != null ? atomKey : keyExpr;
                            var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [makeAST(EVar(name)), finalKey, args[1]]));
                            makeAST(EMatch(PVar(name), putCall));
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
    
    /**
     * Map builder collapse pass
     * 
     * WHY: Sequential Map.put calls create verbose imperative code
     * WHAT: Collapses Map.put builder patterns into literal map syntax
     * HOW: Detects temp map variable with sequential puts and converts to literal
     * 
     * PATTERN:
     * Before:
     *   temp = %{}
     *   temp = Map.put(temp, :key1, value1)
     *   temp = Map.put(temp, :key2, value2)
     *   temp
     * 
     * After:
     *   %{key1: value1, key2: value2}
     */
    public static function mapBuilderCollapsePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(statements):
                    var collapsed = tryCollapseMapBuilder(statements, node.metadata, node.pos);
                    if (collapsed != null) {
                        return collapsed;
                    }
                    return node;
                default:
                    return node;
            }
        });
    }
    
    private static function tryCollapseMapBuilder(statements: Array<ElixirAST>, metadata: ElixirMetadata, pos: Position): Null<ElixirAST> {
        if (statements == null || statements.length < 2) {
            return null;
        }

        var tempName: String = null;
        var pairs: Array<EMapPair> = null;

        switch(statements[0].def) {
            case EMatch(pattern, initExpr):
                switch pattern {
                    case PVar(name):
                        tempName = name;
#if debug_map_literal
                        trace('[MapCollapse] temp var=' + tempName);
#end
                    default:
                        return null;
                }

                switch(initExpr.def) {
                    case EMap(initialPairs):
                        pairs = initialPairs.copy();
#if debug_map_literal
                        trace('[MapCollapse] initial pairs count=' + pairs.length);
#end
                    default:
                        return null;
                }
            default:
                return null;
        }

        if (tempName == null) {
            return null;
        }

        for (i in 1...statements.length - 1) {
            var stmt = statements[i];
            switch(stmt.def) {
                case EBinary(Match, leftExpr, rightExpr):
                    switch(leftExpr.def) {
                        case EVar(varName) if (varName == tempName):
#if debug_map_literal
                            trace('[MapCollapse] assignment to ' + varName);
#end
                        default:
                            return null;
                    }

                    switch(rightExpr.def) {
                        case ERemoteCall(moduleExpr, funcName, args) if (funcName == "put" && args.length == 3):
#if debug_map_literal
                            trace('[MapCollapse] Map.put detected');
#end
                            switch(moduleExpr.def) {
                                case EVar(moduleName) if (moduleName == "Map"):
                                default:
                                    return null;
                            }

                            switch(args[0].def) {
                                case EVar(varName) if (varName == tempName):
                                default:
                                    return null;
                            }

                            pairs.push({key: args[1], value: args[2]});
#if debug_map_literal
                            trace('[MapCollapse] appended pair #' + pairs.length);
#end
                        default:
                            return null;
                    }
                default:
                    return null;
            }
        }

        switch(statements[statements.length - 1].def) {
            case EVar(varName) if (varName == tempName):
#if debug_map_literal
                trace('[MapCollapse] success - collapsing to literal');
#end
                return makeASTWithMeta(EMap(pairs), metadata, pos);
            default:
                return null;
        }
    }
    
    /**
     * List effect lifting pass
     * 
     * WHY: Side-effecting expressions in list literals can cause evaluation order issues
     * WHAT: Lifts side-effects out of list literals into temporary variables
     * HOW: Detects complex expressions in lists and extracts them to temp vars
     * 
     * PATTERN:
     * Before: [compute(), other.method(), value]
     * After:
     *   tmp1 = compute()
     *   tmp2 = other.method()
     *   [tmp1, tmp2, value]
     */
    public static function listEffectLiftingPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EList(items):
                    var needsLifting = false;
                    for (item in items) {
                        if (hasComplexExpression(item)) {
                            needsLifting = true;
                            break;
                        }
                    }
                    
                    if (needsLifting) {
                        var statements: Array<ElixirAST> = [];
                        var newItems: Array<ElixirAST> = [];
                        var tempCounter = 0;
                        
                        for (item in items) {
                            if (hasComplexExpression(item)) {
                                var tempVar = "tmp_list_" + tempCounter++;
                                statements.push(makeAST(EMatch(PVar(tempVar), item)));
                                newItems.push(makeAST(EVar(tempVar)));
                            } else {
                                newItems.push(item);
                            }
                        }
                        
                        statements.push(makeAST(EList(newItems)));
                        return makeAST(EBlock(statements));
                    }
                    
                    return node;
                default:
                    return node;
            }
        });
    }
    
    private static function hasComplexExpression(ast: ElixirAST): Bool {
        return switch(ast.def) {
            case ECall(_, _, _): true;
            case ERemoteCall(_, _, _): true;
            case EBinary(_, _, _): true;
            case EUnary(_, _): true;
            case ECase(_, _): true;
            case EIf(_, _, _): true;
            case ECond(_): true;
            case EBlock(_): true;
            default: false;
        };
    }

    /**
     * Map Iterator Transformation Pass (migrated from ElixirASTTransformer)
     * Transforms Map iterator patterns from g.next() to idiomatic Enum.each with {k, v} destructuring.
     *
     * WHY: Builder emits Map iterator machinery for Haxe MapKeyValueIterator.
     * WHAT: Detect Enum.reduce_while loops that drive a Map iterator and rewrite to Enum.each(map, fn {k, v} -> ... end)
     * HOW: Scan loop function for iterator method chains, extract key/value binders and body, drop infra tuples {:cont, ...}.
     */
    public static function mapIteratorTransformPass(ast: ElixirAST): ElixirAST {
        if (ast == null) return null;

        #if debug_map_iterator
        trace("[MapIteratorTransform] ===== MAP ITERATOR TRANSFORM PASS STARTING =====");
        switch(ast.def) {
            case EModule(name, _):
                trace('[MapIteratorTransform] Processing module: ' + name);
            default:
                trace('[MapIteratorTransform] Processing non-module AST node');
        }
        #end

        return ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case ERemoteCall(module, funcName, args):
                    switch(module.def) {
                        case EVar(modName) if (modName == "Enum" && funcName == "reduce_while" && args != null && args.length >= 3):
                            #if debug_map_iterator
                            trace('[MapIteratorTransform] Found Enum.reduce_while - checking for Map iterator patterns');
                            #end
                            var loopFunc = args[2];

                            // Detect iterator usage within the loop function body
                            function hasMapIteratorCalls(ast: ElixirAST): Bool {
                                if (ast == null) return false;
                                var found = false;
                                var depth = 0;
                                function scan(n: ElixirAST): Void {
                                    if (n == null || n.def == null) return;
                                    depth++;
                                    #if debug_map_iterator
                                    if (depth <= 4) {
                                        var nodeType = n.def != null ? Type.enumConstructor(n.def) : "null";
                                        trace('[MapIteratorTransform] Depth ' + depth + ' - Node type: ' + nodeType);
                                    }
                                    #end
                                    switch(n.def) {
                                        case EField(obj, field):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Field access found: ' + field);
                                            #end
                                            if (field == "key_value_iterator" || field == "has_next" || field == "next" || field == "key" || field == "value") {
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] *** FOUND MAP ITERATOR FIELD: ' + field + ' ***');
                                                #end
                                                found = true;
                                            }
                                            scan(obj);
                                        case ECall(target, funcName, args):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning: Found call to ' + funcName);
                                            #end
                                            if (target != null) {
                                                switch(target.def) {
                                                    case EField(_, field):
                                                        #if debug_map_iterator
                                                        trace('[MapIteratorTransform] Call is on field: ' + field);
                                                        #end
                                                        if (field == "key_value_iterator" || field == "has_next" || field == "next" || field == "key" || field == "value") {
                                                            #if debug_map_iterator
                                                            trace('[MapIteratorTransform] *** FOUND MAP ITERATOR CALL: ' + field + '() ***');
                                                            #end
                                                            found = true;
                                                        }
                                                    default:
                                                }
                                                scan(target);
                                            }
                                            if (args != null) for (arg in args) scan(arg);
                                        case EFn(clauses):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning function with ' + clauses.length + ' clauses');
                                            #end
                                            for (c in clauses) if (c.body != null) scan(c.body);
                                        case EBlock(exprs):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning block with ' + exprs.length + ' expressions');
                                            #end
                                            for (e in exprs) scan(e);
                                        case EIf(cond, t, e):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning if statement');
                                            #end
                                            scan(cond);
                                            scan(t);
                                            if (e != null) scan(e);
                                        case EMatch(_, value):
                                            scan(value);
                                        case ETuple(items):
                                            for (item in items) scan(item);
                                        default:
                                            #if debug_map_iterator
                                            if (depth <= 4) {
                                                var nodeType = Type.enumConstructor(n.def);
                                                trace('[MapIteratorTransform] Other node type: ' + nodeType);
                                            }
                                            #end
                                    }
                                    depth--;
                                }
                                scan(ast);
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Scan complete for AST, found iterator patterns: ' + found);
                                #end
                                return found;
                            }

                            #if debug_map_iterator
                            trace('[MapIteratorTransform] Checking loopFunc for Map iterator calls...');
                            #end

                            if (hasMapIteratorCalls(loopFunc)) {
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Found Map iteration pattern in reduce_while - transforming to Enum.each');
                                #end

                                // Extract the map variable from the initial value (second argument)
                                var mapVar = switch(args[1].def) {
                                    case ETuple([mapExpr, _]) | ETuple([mapExpr]):
                                        switch(mapExpr.def) {
                                            case EVar(name): name;
                                            default: null;
                                        }
                                    case EVar(name): name;
                                    default: null;
                                };
                                if (mapVar == null) mapVar = "colors"; // fallback

                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Map variable identified: ' + mapVar);
                                #end

                                var keyVarName = "name";
                                var valueVarName = "hex";
                                var loopBody: ElixirAST = null;

                                switch(loopFunc.def) {
                                    case EFn(clauses) if (clauses.length > 0):
                                        var body = clauses[0].body;
                                        switch(body.def) {
                                            case EIf(_, thenBranch, _):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Processing if branch for body extraction');
                                                #if debug_ast_structure
                                                ASTUtils.debugAST(thenBranch, 0, 3);
                                                #end
                                                #end
                                                var allExprs = ASTUtils.flattenBlocks(thenBranch);
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Flattened ' + allExprs.length + ' expressions from then branch');
                                                #end
                                                // Extract variable names from iterator assignments
                                                for (expr in allExprs) {
                                                    switch(expr.def) {
                                                        case EMatch(PVar(varName), rhs):
                                                            if (ASTUtils.containsIteratorPattern(rhs)) {
                                                                switch(rhs.def) {
                                                                    case EField(_, "key"):
                                                                        keyVarName = varName;
                                                                        #if debug_map_iterator
                                                                        trace('[MapIteratorTransform] Found key variable: ' + keyVarName);
                                                                        #end
                                                                    case EField(_, "value"):
                                                                        valueVarName = varName;
                                                                        #if debug_map_iterator
                                                                        trace('[MapIteratorTransform] Found value variable: ' + valueVarName);
                                                                        #end
                                                                    default:
                                                                        var fieldChain = [];
                                                                        var current = rhs;
                                                                        while (current != null) {
                                                                            switch(current.def) {
                                                                                case EField(obj, field):
                                                                                    fieldChain.push(field);
                                                                                    current = obj;
                                                                                case ECall(func, _, _):
                                                                                    current = func;
                                                                                default:
                                                                                    current = null;
                                                                            }
                                                                        }
                                                                        if (fieldChain.length > 0) {
                                                                            if (fieldChain[0] == "key") {
                                                                                keyVarName = varName;
                                                                                #if debug_map_iterator
                                                                                trace('[MapIteratorTransform] Found key variable via chain: ' + keyVarName);
                                                                                #end
                                                                            } else if (fieldChain[0] == "value") {
                                                                                valueVarName = varName;
                                                                                #if debug_map_iterator
                                                                                trace('[MapIteratorTransform] Found value variable via chain: ' + valueVarName);
                                                                                #end
                                                                            }
                                                                        }
                                                                }
                                                            }
                                                        default:
                                                    }
                                                }
                                                var cleanExprs = ASTUtils.filterIteratorAssignments(allExprs);
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] After filtering: ' + cleanExprs.length + ' expressions remain');
                                                #end
                                                var bodyExprs = [];
                                                for (expr in cleanExprs) {
                                                    switch(expr.def) {
                                                        case ETuple(elements):
                                                            var isCont = elements.length > 0 && switch(elements[0].def) {
                                                                case EAtom(atom): atom == "cont";
                                                                default: false;
                                                            };
                                                            if (!isCont) bodyExprs.push(expr);
                                                        default:
                                                            bodyExprs.push(expr);
                                                    }
                                                }
                                                loopBody = if (bodyExprs.length == 1) bodyExprs[0] else if (bodyExprs.length > 1) makeAST(EBlock(bodyExprs)) else null;
                                            default:
                                        }
                                    default:
                                }

                                if (loopBody != null) {
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Creating Enum.each with {' + keyVarName + ', ' + valueVarName + '} destructuring');
                                    trace('[MapIteratorTransform] Map variable: ' + mapVar);
                                    trace('[MapIteratorTransform] Body extracted, creating transformation');
                                    #end
                                    var transformedAST = makeAST(ERemoteCall(
                                        makeAST(EVar("Enum")),
                                        "each",
                                        [
                                            makeAST(EVar(mapVar)),
                                            makeAST(EFn([{
                                                args: [PTuple([PVar(keyVarName), PVar(valueVarName)])],
                                                guard: null,
                                                body: loopBody
                                            }]))
                                        ]
                                    ));
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] *** TRANSFORMATION COMPLETE - RETURNING NEW AST ***');
                                    #end
                                    return transformedAST;
                                }
                            }
                        default:
                    }
                default:
            }
            return node;
        });
    }

    // Internal helper: conservative check for Map iterator signals
    private static function containsIteratorPatterns(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        var hasKeyValueIterator = false;
        var hasHasNext = false;
        var hasNext = false;
        function scan(node: ElixirAST): Void {
            if (node == null || node.def == null) return;
            switch(node.def) {
                case EField(obj, field):
                    if (field == "key_value_iterator") {
                        hasKeyValueIterator = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found key_value_iterator field');
                        #end
                    } else if (field == "has_next") {
                        hasHasNext = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found has_next field');
                        #end
                    } else if (field == "next") {
                        hasNext = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found next field');
                        #end
                    }
                    scan(obj);
                case ECall(func, _, args):
                    switch(func.def) {
                        case EField(obj, field):
                            if (field == "key_value_iterator" || field == "has_next" || field == "next") {
                                if (field == "key_value_iterator") hasKeyValueIterator = true;
                                if (field == "has_next") hasHasNext = true;
                                if (field == "next") hasNext = true;
                                #if debug_map_iterator
                                trace('[MapIteratorTransform/scan] Found iterator method call: ' + field + '()');
                                #end
                            }
                            scan(obj);
                        default:
                            scan(func);
                    }
                    if (args != null) for (arg in args) scan(arg);
                case EFn(clauses):
                    for (clause in clauses) if (clause.body != null) scan(clause.body);
                case EBlock(exprs):
                    for (expr in exprs) scan(expr);
                case EIf(cond, thenBranch, elseBranch):
                    scan(cond);
                    scan(thenBranch);
                    if (elseBranch != null) scan(elseBranch);
                case ETuple(elements):
                    for (elem in elements) scan(elem);
                case ERemoteCall(module, _, args):
                    scan(module);
                    if (args != null) for (arg in args) scan(arg);
                case EVar(_), EAtom(_), EString(_):
                default:
                    #if debug_map_iterator
                    var nodeType = Type.enumConstructor(node.def);
                    trace('[MapIteratorTransform/scan] Unhandled node type: ' + nodeType);
                    #end
            }
        }
        scan(ast);
        var result = hasKeyValueIterator;
        #if debug_map_iterator
        if (result) trace('[MapIteratorTransform/scan] ✅ PATTERN DETECTED - hasKeyValueIterator: ' + hasKeyValueIterator + ', hasHasNext: ' + hasHasNext + ', hasNext: ' + hasNext);
        #end
        return result;
    }

    // Debug helper to pretty-print nodes
    #if debug_map_iterator
    private static function printASTStructure(ast: ElixirAST, depth: Int = 0): String {
        if (ast == null || ast.def == null) return "null";
        if (depth > 3) return "...";
        var nodeType = Type.enumConstructor(ast.def);
        return switch(ast.def) {
            case EField(obj, field): '$nodeType(.$field on ${printASTStructure(obj, depth + 1)})';
            case ECall(func, _, args): var argsStr = args != null ? '[${args.length} args]' : '[no args]'; '$nodeType($argsStr, func=${printASTStructure(func, depth + 1)})';
            case EVar(name): '$nodeType($name)';
            case EAtom(atom): '$nodeType(:$atom)';
            default: nodeType;
        }
    }
    #end
}

#end
/**
 * MapAndCollectionTransforms
 *
 * WHAT
 * - Normalizes Map/Keyword/List building patterns into idiomatic Elixir forms by
 *   collapsing builder blocks and standardizing access/put operations.
 *
 * WHY
 * - Haxe desugarings and intermediate temps often produce verbose Map.put chains
 *   and uneven List concatenations. This pass improves readability and reduces
 *   chances of warnings.
 *
 * HOW
 * - Detects Map.put pipelines and rewrites to literal maps when safe.
 * - Ensures keyword lists use standard literal syntax where possible.
 *
 * EXAMPLES
 * Haxe:
 *   var m = {}; m = Map.put(m, :a, 1); m = Map.put(m, :b, 2)
 * Elixir (after):
 *   %{a: 1, b: 2}
 */
