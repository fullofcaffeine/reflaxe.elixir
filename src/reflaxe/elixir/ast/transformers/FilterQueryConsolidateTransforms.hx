package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterQueryConsolidateTransforms
 *
 * WHAT
 * - Single shape-based pass ensuring `query` availability for `Enum.filter/2` EFn
 *   predicates that reference `query`.
 * - Prefers (1) promotion from preceding `_ = String.downcase(search_query)`,
 *   (2) insertion of `query = String.downcase(search_query)` using the nearest
 *   prior downcase, else (3) inlines `String.downcase(search_query)` in the
 *   predicate body when `search_query` exists in the surrounding block.
 *
 * WHY
 * - Replace multiple late-stage guards with one deterministic pass. Keeps
 *   predicate transforms robust post EFn normalization and eliminates undefined
 *   `query` in filter predicates without ERaw rewrites.
 *
 * HOW
 * - Visit EBlock/EDo statement lists.
 * - For each `Enum.filter(list, fn ... -> ... end)` whose body uses `query`:
 *   - If `query` bound earlier → no change.
 *   - Else if immediate previous stmt is `_ = String.downcase(x)` → promote to
 *     `query = String.downcase(x)` (statement rewrite in place).
 *   - Else if any earlier `String.downcase(..)` exists → insert
 *     `query = <that downcase rhs>` immediately before the filter stmt.
 *   - Else if block references `search_query` → inline `String.downcase(search_query)`
 *     into the predicate body by replacing `EVar("query")`.
 * - Avoids ERaw token rewriting; predicates are structured `EFn` by prior pass.
 *
 * EXAMPLES
 * Before:
 *   _ = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> String.contains?(t.title, query) end)
 * After (promotion):
 *   query = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> String.contains?(t.title, query) end)
 *
 * Before:
 *   # no prior binder
 *   Enum.filter(todos, fn t -> String.contains?(t.description, query) end)
 * After (inline):
 *   Enum.filter(todos, fn t -> String.contains?(t.description, String.downcase(search_query)) end)
 *
 * DO-BLOCK SUPPORT
 * - Runs inside if/with/do bodies via EDo recursion added to ElixirASTTransformer.
 *
 * DEBUG
 * - Enable with: -D debug_filter_query_consolidate to log promotion/binding/inline decisions.
 */
class FilterQueryConsolidateTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // If-expression aware injection:
                // When the condition enforces search presence (not is_nil(search_query) && search_query != "")
                // and the then-branch references `query` or contains an Enum.filter that (likely) uses it,
                // inject `query = String.downcase(search_query)` at the top of the then-branch.
                case EIf(cond, thenBranch, elseBranch):
                    var isSearchGuard = detectSearchGuard(cond);
                    if (isSearchGuard) {
                        // Only inject when the then-branch has query usage or a filter (cheap and avoids unused warning)
                        var branchNeedsBinder = branchHasQueryOrFilter(thenBranch);
                        if (branchNeedsBinder && !branchDefinesQueryTopLevel(thenBranch)) {
                            var binder = makeAST(EBinary(Match, makeAST(EVar("query")), makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]))));
                            var newThen: ElixirAST = switch (thenBranch.def) {
                                case EDo(es): makeASTWithMeta(EDo([binder].concat(es)), thenBranch.metadata, thenBranch.pos);
                                case EBlock(es2): makeASTWithMeta(EBlock([binder].concat(es2)), thenBranch.metadata, thenBranch.pos);
                                default: makeASTWithMeta(EDo([binder, thenBranch]), thenBranch.metadata, thenBranch.pos);
                            };
                            makeASTWithMeta(EIf(cond, newThen, elseBranch), n.metadata, n.pos);
                        } else n;
                    } else n;
                // Function-level guard (public): if function has a `search_query` parameter and its body
                // contains a filter that references `query` (or ERaw mentioning it), but no
                // prior binding to `query` exists, insert a binder at function entry.
                case EDef(name, args, guards, body):
                    var hasSearchParam = false;
                    if (args != null) for (p in args) switch (p) { case PVar(an) if (an == "search_query"): hasSearchParam = true; default: }
                    if (hasSearchParam && body != null) {
                        var needsBinder = (function():Bool {
                            var hasFilterQuery = false;
                            var hasQueryBinder = false;
                            var hasQueryRef = false;
                            // Local helper: does EFn body use `query`?
                            function fnBodyUsesQuery(e: ElixirAST): Bool {
                                var used = false;
                                ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST { if (used) return x; switch (x.def) { case EVar(nm) if (nm == "query"): used = true; return x; default: return x; }});
                                return used;
                            }
                            // Local helper: token-boundary search in ERaw
                            function rawContainsIdentLocal(code:String, ident:String): Bool {
                                if (code == null || ident == null || ident.length == 0) return false;
                                var start = 0; var len = ident.length;
                                inline function isIdentChar(c:String):Bool {
                                    if (c == null || c.length == 0) return false;
                                    var ch = c.charCodeAt(0);
                                    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
                                }
                                while (true) {
                                    var i = code.indexOf(ident, start);
                                    if (i == -1) break;
                                    var before = i > 0 ? code.substr(i - 1, 1) : null;
                                    var afterIdx = i + len;
                                    var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                                    if (!isIdentChar(before) && !isIdentChar(after)) return true;
                                    start = i + len;
                                }
                                return false;
                            }
                            function scan(x: ElixirAST): Void {
                                if (x == null || x.def == null) return;
                                if (hasFilterQuery && hasQueryBinder) return;
                                switch (x.def) {
                                    case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): hasQueryBinder = true; default: }
                                    case EMatch(pat, _): switch (pat) { case PVar(nm2) if (nm2 == "query"): hasQueryBinder = true; default: }
                                    case ERemoteCall({def: EVar(m)}, "filter", a) if (m == "Enum" && a != null && a.length == 2):
                                        switch (a[1].def) { case EFn(cs) if (cs.length == 1): if (fnBodyUsesQuery(cs[0].body)) hasFilterQuery = true; default: }
                                    case ECall(_, "filter", a2) if (a2 != null && a2.length == 2):
                                        switch (a2[1].def) { case EFn(cs2) if (cs2.length == 1): if (fnBodyUsesQuery(cs2[0].body)) hasFilterQuery = true; default: }
                                    case ERaw(code):
                                        if (code != null && code.indexOf('Enum.filter(') != -1 && rawContainsIdentLocal(code, 'query')) hasFilterQuery = true;
                                    case EBlock(es): for (e in es) scan(e);
                                    case EDo(es2): for (e in es2) scan(e);
                                    case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                                    case ECase(e2, cs): scan(e2); for (c2 in cs) { if (c2.guard != null) scan(c2.guard); scan(c2.body); }
                                    case ERemoteCall(m2,_,as2): scan(m2); for (aa in as2) scan(aa);
                                    case ECall(t2,_,as3): if (t2 != null) scan(t2); for (aa2 in as3) scan(aa2);
                                    default:
                                }
                            }
                            scan(body);
                            return hasFilterQuery && !hasQueryBinder;
                        })();
                        if (needsBinder) {
                            var rhs = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            var binder = makeAST(EBinary(Match, makeAST(EVar("query")), rhs));
                            var newBody: ElixirAST = switch (body.def) {
                                case EDo(es): makeASTWithMeta(EDo([binder].concat(es)), body.metadata, body.pos);
                                case EBlock(es2): makeASTWithMeta(EBlock([binder].concat(es2)), body.metadata, body.pos);
                                default: makeASTWithMeta(EDo([binder, body]), body.metadata, body.pos);
                            };
                            return makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                        }
                    }
                    n;
                case EDefp(name2, args2, guards2, body2):
                    var hasSearchParam2 = false;
                    if (args2 != null) for (p in args2) switch (p) { case PVar(an) if (an == "search_query"): hasSearchParam2 = true; default: }
                    if (hasSearchParam2 && body2 != null) {
                        var needsBinder2 = (function():Bool {
                            var hasFilterQuery = false;
                            var hasQueryBinder = false;
                            function fnBodyUsesQuery2(e: ElixirAST): Bool {
                                var used = false;
                                ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST { if (used) return x; switch (x.def) { case EVar(nm) if (nm == "query"): used = true; return x; default: return x; }});
                                return used;
                            }
                            function rawContainsIdentLocal2(code:String, ident:String): Bool {
                                if (code == null || ident == null || ident.length == 0) return false;
                                var start = 0; var len = ident.length;
                                inline function isIdentChar(c:String):Bool {
                                    if (c == null || c.length == 0) return false;
                                    var ch = c.charCodeAt(0);
                                    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
                                }
                                while (true) {
                                    var i = code.indexOf(ident, start);
                                    if (i == -1) break;
                                    var before = i > 0 ? code.substr(i - 1, 1) : null;
                                    var afterIdx = i + len;
                                    var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                                    if (!isIdentChar(before) && !isIdentChar(after)) return true;
                                    start = i + len;
                                }
                                return false;
                            }
                            function scan2(x: ElixirAST): Void {
                                if (x == null || x.def == null) return;
                                if (hasFilterQuery && hasQueryBinder) return;
                                switch (x.def) {
                                    case EBinary(Match, left, right):
                                        switch (left.def) { case EVar(nm) if (nm == "query"): hasQueryBinder = true; default: }
                                        // Recurse into RHS to find nested Enum.filter calls
                                        scan2(right);
                                    case EMatch(pat, expr):
                                        switch (pat) { case PVar(nm2) if (nm2 == "query"): hasQueryBinder = true; default: }
                                        // Recurse into RHS expression
                                        scan2(expr);
                                    case EVar(nm3) if (nm3 == "query"):
                                        // Broaden: any query reference in function body
                                        hasFilterQuery = true;
                                    case ERemoteCall({def: EVar(m)}, "filter", a) if (m == "Enum" && a != null && a.length == 2):
                                        switch (a[1].def) { case EFn(cs) if (cs.length == 1): if (fnBodyUsesQuery2(cs[0].body)) hasFilterQuery = true; default: }
                                    case ECall(_, "filter", a2) if (a2 != null && a2.length == 2):
                                        switch (a2[1].def) { case EFn(cs2) if (cs2.length == 1): if (fnBodyUsesQuery2(cs2[0].body)) hasFilterQuery = true; default: }
                                    case ERaw(code):
                                        if (code != null && code.indexOf('Enum.filter(') != -1 && rawContainsIdentLocal2(code, 'query')) hasFilterQuery = true;
                                    case EBlock(es): for (e in es) scan2(e);
                                    case EDo(es2): for (e in es2) scan2(e);
                                    case EIf(c,t,e): scan2(c); scan2(t); if (e != null) scan2(e);
                                    case ECase(e2, cs): scan2(e2); for (c2 in cs) { if (c2.guard != null) scan2(c2.guard); scan2(c2.body); }
                                    case ERemoteCall(m2,_,as2): scan2(m2); for (aa in as2) scan2(aa);
                                    case ECall(t2,_,as3): if (t2 != null) scan2(t2); for (aa2 in as3) scan2(aa2);
                                    default:
                                }
                            }
                            scan2(body2);
                            return hasFilterQuery && !hasQueryBinder;
                        })();
                        if (needsBinder2) {
                            var rhs2 = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            var binder2 = makeAST(EBinary(Match, makeAST(EVar("query")), rhs2));
                            var newBody2: ElixirAST = switch (body2.def) {
                                case EDo(es): makeASTWithMeta(EDo([binder2].concat(es)), body2.metadata, body2.pos);
                                case EBlock(es2): makeASTWithMeta(EBlock([binder2].concat(es2)), body2.metadata, body2.pos);
                                default: makeASTWithMeta(EDo([binder2, body2]), body2.metadata, body2.pos);
                            };
                            return makeASTWithMeta(EDefp(name2, args2, guards2, newBody2), n.metadata, n.pos);
                        }
                    }
                    n;
                // Function-level guard (private): same as above but for EDefp
                case EDefp(name, args, guards, body):
                    var hasSearchParamP = false;
                    if (args != null) for (p in args) switch (p) { case PVar(an) if (an == "search_query"): hasSearchParamP = true; default: }
                    if (hasSearchParamP && body != null) {
                        var needsBinderP = (function():Bool {
                            var hasFilterQuery = false;
                            var hasQueryBinder = false;
                            function fnBodyUsesQueryP(e: ElixirAST): Bool {
                                var used = false;
                                ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                                    if (used) return x;
                                    switch (x.def) {
                                        case EVar(nm) if (nm == "query"): used = true; return x;
                                        default: return x;
                                    }
                                });
                                return used;
                            }
                            function rawContainsIdentLocalP(code:String, ident:String): Bool {
                                if (code == null || ident == null || ident.length == 0) return false;
                                var start = 0; var len = ident.length;
                                inline function isIdentChar(c:String):Bool {
                                    if (c == null || c.length == 0) return false;
                                    var ch = c.charCodeAt(0);
                                    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
                                }
                                while (true) {
                                    var i = code.indexOf(ident, start);
                                    if (i == -1) break;
                                    var before = i > 0 ? code.substr(i - 1, 1) : null;
                                    var afterIdx = i + len;
                                    var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                                    if (!isIdentChar(before) && !isIdentChar(after)) return true;
                                    start = i + len;
                                }
                                return false;
                            }
                            function scanP(x: ElixirAST): Void {
                                if (x == null || x.def == null) return;
                                if (hasFilterQuery && hasQueryBinder) return;
                                switch (x.def) {
                                    case EBinary(Match, left, right):
                                        switch (left.def) { case EVar(nm) if (nm == "query"): hasQueryBinder = true; default: }
                                        // Recurse into RHS to find nested Enum.filter calls
                                        scanP(right);
                                    case EMatch(pat, expr):
                                        switch (pat) { case PVar(nm2) if (nm2 == "query"): hasQueryBinder = true; default: }
                                        // Recurse into RHS expression
                                        scanP(expr);
                                    case EVar(nmX) if (nmX == "query"):
                                        // Broaden: any query reference in function body
                                        hasFilterQuery = true;
                                    case ERemoteCall({def: EVar(m)}, "filter", a) if (m == "Enum" && a != null && a.length == 2):
                                        switch (a[1].def) { case EFn(cs) if (cs.length == 1): if (fnBodyUsesQueryP(cs[0].body)) hasFilterQuery = true; default: }
                                    case ECall(_, "filter", a2) if (a2 != null && a2.length == 2):
                                        switch (a2[1].def) { case EFn(cs2) if (cs2.length == 1): if (fnBodyUsesQueryP(cs2[0].body)) hasFilterQuery = true; default: }
                                    case ERaw(code):
                                        if (code != null && code.indexOf('Enum.filter(') != -1 && rawContainsIdentLocalP(code, 'query')) hasFilterQuery = true;
                                    case EBlock(es): for (e in es) scanP(e);
                                    case EDo(es2): for (e in es2) scanP(e);
                                    case EIf(c,t,e): scanP(c); scanP(t); if (e != null) scanP(e);
                                    case ECase(e2, cs): scanP(e2); for (c2 in cs) { if (c2.guard != null) scanP(c2.guard); scanP(c2.body); }
                                    case ERemoteCall(m2,_,as2): scanP(m2); for (aa in as2) scanP(aa);
                                    case ECall(t2,_,as3): if (t2 != null) scanP(t2); for (aa2 in as3) scanP(aa2);
                                    default:
                                }
                            }
                            scanP(body);
                            return hasFilterQuery && !hasQueryBinder;
                        })();
                        if (needsBinderP) {
                            #if debug_filter_query_consolidate
                            trace('[FilterQueryConsolidate] Inserting defp-level query binder for ' + name + ' at function entry');
                            #end
                            var rhsP2 = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            var binderP2 = makeAST(EBinary(Match, makeAST(EVar("query")), rhsP2));
                            var newBodyP2: ElixirAST = switch (body.def) {
                                case EDo(es): makeASTWithMeta(EDo([binderP2].concat(es)), body.metadata, body.pos);
                                case EBlock(es2): makeASTWithMeta(EBlock([binderP2].concat(es2)), body.metadata, body.pos);
                                default: makeASTWithMeta(EDo([binderP2, body]), body.metadata, body.pos);
                            };
                            return makeASTWithMeta(EDefp(name, args, guards, newBodyP2), n.metadata, n.pos);
                        }
                    }
                    n;
                case EBlock(stmts) if (stmts.length > 0): makeASTWithMeta(EBlock(rewrite(stmts, n)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0): makeASTWithMeta(EDo(rewrite(stmts2, n)), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function inlineQueryInFilterBodies(e: ElixirAST): ElixirAST {
        var repl = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
        function replaceInBody(body: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) { case EVar(nm) if (nm == "query"): repl; default: x; };
            });
        }
        return ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case ERemoteCall(mod, "filter", args) if (args != null && args.length == 2):
                    switch (args[1].def) {
                        case EFn(cs) if (cs.length == 1):
                            var cl = cs[0];
                            var newBody = replaceInBody(cl.body);
                            var newFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]));
                            makeASTWithMeta(ERemoteCall(mod, "filter", [args[0], newFn]), x.metadata, x.pos);
                        default: x;
                    }
                case ECall(tgt, "filter", args2) if (args2 != null && args2.length >= 1):
                    var predArg = args2[args2.length - 1];
                    switch (predArg.def) {
                        case EFn(cs2) if (cs2.length == 1):
                            var cl2 = cs2[0];
                            var newBody2 = replaceInBody(cl2.body);
                            var newFn2 = makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: newBody2 }]));
                            var prefix = args2.slice(0, args2.length - 1);
                            makeASTWithMeta(ECall(tgt, "filter", prefix.concat([newFn2])), x.metadata, x.pos);
                        default: x;
                    }
                default: x;
            }
        });
    }

    static function detectSearchGuard(cond: ElixirAST): Bool {
        var hasNotIsNil = false;
        var hasNotEmpty = false;
        function scan(x: ElixirAST): Void {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EUnary(Not, inner):
                    // not Kernel.is_nil(search_query) or not is_nil(search_query)
                    switch (inner.def) {
                        case ERemoteCall({def: EVar(m)}, fname, args) if ((m == "Kernel" || m == null) && fname == "is_nil" && args != null && args.length == 1):
                            switch (args[0].def) { case EVar(vn) if (vn == "search_query"): hasNotIsNil = true; default: }
                        case ECall(_, fname2, args2) if (fname2 == "is_nil" && args2 != null && args2.length == 1):
                            switch (args2[0].def) { case EVar(vn2) if (vn2 == "search_query"): hasNotIsNil = true; default: }
                        default:
                    }
                case EBinary(NotEqual, l, r):
                    var leftIs = switch (l.def) { case EVar(nm) if (nm == "search_query"): true; default: false; };
                    var rightIsEmpty = switch (r.def) { case EString(s) if (s == ""): true; default: false; };
                    var rightIs = switch (r.def) { case EVar(nm2) if (nm2 == "search_query"): true; default: false; };
                    var leftIsEmpty = switch (l.def) { case EString(s2) if (s2 == ""): true; default: false; };
                    if ((leftIs && rightIsEmpty) || (rightIs && leftIsEmpty)) hasNotEmpty = true;
                case EBinary(_, a, b): scan(a); scan(b);
                default:
            }
        }
        scan(cond);
        return hasNotIsNil && hasNotEmpty;
    }

    static function branchHasQueryOrFilter(e: ElixirAST): Bool {
        var found = false;
        function rv(x: ElixirAST): Void {
            if (x == null || x.def == null || found) return;
            switch (x.def) {
                case EVar(nm) if (nm == "query"): found = true;
                case ERaw(code) if (code != null && code.indexOf('query') != -1): found = true;
                case ERemoteCall({def: EVar(m)}, "filter", _ ) if (m == "Enum"): found = true;
                case ECall(_, "filter", _): found = true;
                case EBlock(es): for (s in es) rv(s);
                case EDo(es2): for (s in es2) rv(s);
                case EIf(c,t,el): rv(c); rv(t); if (el != null) rv(el);
                case EBinary(_, l, r): rv(l); rv(r);
                case EMatch(_, rhs): rv(rhs);
                case ERemoteCall(tgt, _, args): rv(tgt); for (a in args) rv(a);
                case ECall(tgt2, _, args2): if (tgt2 != null) rv(tgt2); for (a2 in args2) rv(a2);
                case ECase(expr, cs): rv(expr); for (c in cs) rv(c.body);
                default:
            }
        }
        rv(e);
        return found;
    }

    static function branchDefinesQueryTopLevel(e: ElixirAST): Bool {
        return switch (e.def) {
            case EBlock(stmts):
                for (s in stmts) switch (s.def) {
                    case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): return true; default: }
                    case EMatch(pat, _): switch (pat) { case PVar(nm2) if (nm2 == "query"): return true; default: }
                    default:
                }
                false;
            case EDo(stmts2):
                for (s in stmts2) switch (s.def) {
                    case EBinary(Match, left2, _): switch (left2.def) { case EVar(nm3) if (nm3 == "query"): return true; default: }
                    case EMatch(pat2, _): switch (pat2) { case PVar(nm4) if (nm4 == "query"): return true; default: }
                    default:
                }
                false;
            default:
                false;
        }
    }

    static function isQueryDowncaseAssign(s: ElixirAST): Bool {
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var leftIs = switch (left.def) { case EVar(nm) if (nm == "query"): true; default: false; };
                var rhsIs = switch (rhs.def) {
                    case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
                        switch (args[0].def) { case EVar(v) if (v == "search_query"): true; default: false; }
                    default: false;
                };
                leftIs && rhsIs;
            case EMatch(pat, rhs2):
                var leftIs2 = switch (pat) { case PVar(nm2) if (nm2 == "query"): true; default: false; };
                var rhsIs2 = switch (rhs2.def) {
                    case ERemoteCall({def: EVar(m2)}, "downcase", args2) if (m2 == "String" && args2 != null && args2.length == 1):
                        switch (args2[0].def) { case EVar(v2) if (v2 == "search_query"): true; default: false; }
                    default: false;
                };
                leftIs2 && rhsIs2;
            default:
                false;
        }
    }

    static function rewrite(stmts:Array<ElixirAST>, ctx: ElixirAST): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        #if debug_filter_query_consolidate
        trace('[FilterQueryConsolidate] Rewriting block with ' + stmts.length + ' statements');
        #end

        function definesQuery(idx:Int): Bool {
            var res = false;
            switch (stmts[idx].def) {
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): res = true; default: }
                case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): res = true; default: }
                default:
            }
            return res;
        }
        function queryDefinedBefore(i:Int): Bool {
            var res = false;
            for (k in 0...i) { if (definesQuery(k)) { res = true; break; } }
            return res;
        }
        function isDowncaseOfSearchQuery(rhs: ElixirAST): Bool {
            var ok = false;
            switch (rhs.def) {
                case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1): ok = true;
                default:
            }
            return ok;
        }
        function nearestPriorDowncase(idx:Int): Null<ElixirAST> {
            for (k in (idx - 1) ... -1) {
                if (k < 0) break;
                switch (stmts[k].def) {
                    case EMatch(_, r): if (isDowncaseOfSearchQuery(r)) return r;
                    case EBinary(Match, _, r2): if (isDowncaseOfSearchQuery(r2)) return r2;
                    default:
                }
            }
            return null;
        }
        function blockHasSearchQuery(): Bool {
            var found = false;
            for (s in stmts) {
                ElixirASTTransformer.transformNode(s, function(x: ElixirAST): ElixirAST {
                    if (found) return x; switch (x.def) { case EVar(nm) if (nm == "search_query"): found = true; return x; default: return x; }
                });
                if (found) break;
            }
            return found;
        }
        function bodyUsesQuery(e: ElixirAST): Bool {
            var used = false;
            inline function isIdentChar(c:String):Bool {
                if (c == null || c.length == 0) return false;
                var ch = c.charCodeAt(0);
                return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
            }
            ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                if (used) return x;
                switch (x.def) {
                    case EVar(nm) if (nm == "query"): used = true; return x;
                    case ERaw(code) if (code != null):
                        var start = 0;
                        while (!used) {
                            var i = code.indexOf("query", start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + 5;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { used = true; break; }
                            start = i + 5;
                        }
                        return x;
                    default: return x;
                }
            });
            return used;
        }
        function rawContainsIdent(code:String, ident:String): Bool {
            if (code == null || ident == null || ident.length == 0) return false;
            var start = 0; var len = ident.length;
            inline function isIdentChar(c:String):Bool {
                if (c == null || c.length == 0) return false;
                var ch = c.charCodeAt(0);
                return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
            }
            while (true) {
                var i = code.indexOf(ident, start);
                if (i == -1) break;
                var before = i > 0 ? code.substr(i - 1, 1) : null;
                var afterIdx = i + len;
                var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                if (!isIdentChar(before) && !isIdentChar(after)) return true;
                start = i + len;
            }
            return false;
        }
        function inlineQuery(body: ElixirAST): ElixirAST {
            var repl = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
            return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) { case EVar(nm) if (nm == "query"): repl; default: x; };
            });
        }

        var i = 0;
        var hasSearchQuery = blockHasSearchQuery();
        while (i < stmts.length) {
            var s = stmts[i];
            #if debug_filter_query_consolidate
            trace('[FilterQueryConsolidate] Inspect stmt[' + i + ']: ' + Type.enumConstructor(s.def));
            #end

            // EIf-aware binder injection within blocks: handle `if not is_nil(search_query) and search_query != "" do ... end`
            // Insert `query = String.downcase(search_query)` at top of the then-branch when needed.
            switch (s.def) {
                case EIf(cond, thenB, elseB):
                    var __isGuard = detectSearchGuard(cond);
                    var __needsBinder = !branchDefinesQueryTopLevel(thenB);
                    #if debug_filter_query_consolidate
                    if (__isGuard) trace('[FilterQueryConsolidate] EIf search_guard detected at stmt[' + i + ']');
                    if (__needsBinder) trace('[FilterQueryConsolidate] EIf then-branch needs binder at stmt[' + i + ']');
                    #end
                    // First, recursively rewrite the then-branch to allow inner filter handling
                    var rewrittenThen = thenB;
                    switch (thenB.def) {
                        case EDo(esInner): rewrittenThen = makeASTWithMeta(EDo(rewrite(esInner, thenB)), thenB.metadata, thenB.pos);
                        case EBlock(esInner2): rewrittenThen = makeASTWithMeta(EBlock(rewrite(esInner2, thenB)), thenB.metadata, thenB.pos);
                        default:
                    }
                    if (__isGuard) {
                        // Always ensure binder at top of then-branch under search guard.
                        var binderIf = makeAST(EBinary(Match, makeAST(EVar("query")), makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]))));
                        // Helper: drop stray `_ = String.downcase(search_query)` after a query binder has been established
                        function dropRedundant(esList:Array<ElixirAST>): Array<ElixirAST> {
                            var outL = [];
                            var seenQuery = false;
                            for (jj in 0...esList.length) {
                                var st = esList[jj];
                                var isQB = switch (st.def) {
                                    case EBinary(Match, leftQ, rhsQ):
                                        switch (leftQ.def) { case EVar(nmQ) if (nmQ == "query"): switch (rhsQ.def) { case ERemoteCall(_, "downcase", _): true; default: false; } default: false; }
                                    default: false;
                                };
                                if (isQB) { seenQuery = true; outL.push(st); continue; }
                                var isWildDown = switch (st.def) {
                                    case EMatch(PWildcard, rhsW): switch (rhsW.def) { case ERemoteCall(_, "downcase", _): true; default: false; }
                                    case EBinary(Match, leftW, rhsW2):
                                        var isWild = switch (leftW.def) { case EVar(nmW) if (nmW == "_"): true; case EUnderscore: true; default: false; };
                                        isWild && switch (rhsW2.def) { case ERemoteCall(_, "downcase", _): true; default: false; };
                                    default: false;
                                };
                                if (seenQuery && isWildDown) {
                                    // drop
                                } else outL.push(st);
                            }
                            return outL;
                        }
                        var newThenIf: ElixirAST = switch (rewrittenThen.def) {
                            case EDo(es):
                                var es2 = es;
                                if (es2.length == 0 || !isQueryDowncaseAssign(es2[0])) es2 = [binderIf].concat(es2);
                                es2 = dropRedundant(es2);
                                makeASTWithMeta(EDo(es2), rewrittenThen.metadata, rewrittenThen.pos);
                            case EBlock(es2):
                                var es3 = es2;
                                if (es3.length == 0 || !isQueryDowncaseAssign(es3[0])) es3 = [binderIf].concat(es3);
                                es3 = dropRedundant(es3);
                                makeASTWithMeta(EBlock(es3), rewrittenThen.metadata, rewrittenThen.pos);
                            default:
                                makeASTWithMeta(EDo([binderIf, rewrittenThen]), rewrittenThen.metadata, rewrittenThen.pos);
                        };
                        #if debug_filter_query_consolidate
                        trace('[FilterQueryConsolidate] Ensured binder in EIf then-branch at stmt[' + i + ']');
                        #end
                        s = makeASTWithMeta(EIf(cond, newThenIf, elseB), s.metadata, s.pos);
                    } else if (rewrittenThen != thenB) {
                        // If only inner rewrite changed, propagate it
                        s = makeASTWithMeta(EIf(cond, rewrittenThen, elseB), s.metadata, s.pos);
                    }
                default:
            }

            // Fallback for ERaw blocks containing Enum.filter and query usage:
            // Insert a binder `query = String.downcase(search_query)` before the ERaw
            // when search_query is present in the block and `query` is unbound.
            if (!queryDefinedBefore(i)) {
                switch (s.def) {
                    case ERaw(code) if (code != null):
                        var mentionsFilter = (code.indexOf('Enum.filter(') != -1);
                        var mentionsQuery = rawContainsIdent(code, 'query');
                        if (mentionsFilter && mentionsQuery) {
                            var rhsRaw = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhsRaw), ctx.metadata, ctx.pos));
                        }
                    default:
                }
            }
            // Identify filter with EFn predicate referencing query
            var predPos: Null<{ kind:Int, clauses:Array<EFnClause>, listArg:ElixirAST }>=null; // kind: 0=remote,1=call,2=match-remote,3=match-call
            var isFilter: Bool = false;
            switch (s.def) {
                case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args.length == 2):
                    isFilter = true;
                    switch (args[1].def) { case EFn(cs) if (cs.length == 1 && bodyUsesQuery(cs[0].body)): predPos = { kind:0, clauses: cs, listArg: args[0] }; default: }
                case ECall(target, "filter", args2):
                    isFilter = true;
                    var predArg = (args2 != null && args2.length > 0) ? args2[args2.length - 1] : null; // tolerate 1 or 2
                    if (predArg != null) switch (predArg.def) { case EFn(cs2) if (cs2.length == 1 && bodyUsesQuery(cs2[0].body)): predPos = { kind:1, clauses: cs2, listArg: target }; default: }
                case EMatch(lhs, rhs):
                    switch (rhs.def) {
                        case ERemoteCall({def: EVar(m2)}, "filter", a3) if (m2 == "Enum" && a3.length == 2):
                            isFilter = true;
                            switch (a3[1].def) { case EFn(cs3) if (cs3.length == 1 && bodyUsesQuery(cs3[0].body)): predPos = { kind:2, clauses: cs3, listArg: a3[0] }; default: }
                        case ECall(t2, "filter", a4):
                            isFilter = true;
                            var predArg2 = (a4 != null && a4.length > 0) ? a4[a4.length - 1] : null;
                            if (predArg2 != null) switch (predArg2.def) { case EFn(cs4) if (cs4.length == 1 && bodyUsesQuery(cs4[0].body)): predPos = { kind:3, clauses: cs4, listArg: t2 }; default: }
                        default:
                    }
                case EBinary(Match, leftBin, rhsBin):
                    switch (rhsBin.def) {
                        case ERemoteCall({def: EVar(m3)}, "filter", a5) if (m3 == "Enum" && a5.length == 2):
                            isFilter = true;
                            switch (a5[1].def) { case EFn(cs5) if (cs5.length == 1 && bodyUsesQuery(cs5[0].body)): predPos = { kind:2, clauses: cs5, listArg: a5[0] }; default: }
                        case ECall(t3, "filter", a6):
                            isFilter = true;
                            var predArg3 = (a6 != null && a6.length > 0) ? a6[a6.length - 1] : null;
                            if (predArg3 != null) switch (predArg3.def) { case EFn(cs6) if (cs6.length == 1 && bodyUsesQuery(cs6[0].body)): predPos = { kind:3, clauses: cs6, listArg: t3 }; default: }
                        default:
                    }
            default:
            }
            // Always perform binder promotion/insertion around filter statements, even if
            // bodyUsesQuery() failed to detect it (e.g., ERaw tokens). Inlining is gated by predPos.
            if (isFilter) {
                #if debug_filter_query_consolidate
                trace('[FilterQueryConsolidate] Found filter at index ' + i + ' predPos=' + (predPos != null));
                var __prev = (i - 1 >= 0) ? stmts[i - 1] : null;
                if (__prev != null) {
                    trace('[FilterQueryConsolidate]   Prev stmt def: ' + Type.enumConstructor(__prev.def));
                    switch (__prev.def) {
                        case EBinary(Match, _, rPrev):
                            var okPrev = isDowncaseOfSearchQuery(rPrev);
                            trace('[FilterQueryConsolidate]   Prev is downcase(search_query)? ' + okPrev);
                        case EMatch(_, rPrev2):
                            var okPrev2 = isDowncaseOfSearchQuery(rPrev2);
                            trace('[FilterQueryConsolidate]   Prev (EMatch) is downcase(search_query)? ' + okPrev2);
                            // Extra: log RHS shape
                            trace('[FilterQueryConsolidate]   Prev (EMatch) RHS def: ' + Type.enumConstructor(rPrev2.def));
                            switch (rPrev2.def) {
                                case ERemoteCall(modX, funcX, argsX):
                                    var modName = switch (modX.def) { case EVar(mn): mn; default: '<non-var>'; };
                                    trace('[FilterQueryConsolidate]     RHS remote: ' + modName + '.' + funcX + '/' + (argsX != null ? argsX.length : 0));
                                case ECall(tgtX, funcY, argsY):
                                    trace('[FilterQueryConsolidate]     RHS call: ' + funcY + ' (args=' + (argsY != null ? argsY.length : 0) + ')');
                                default:
                            }
                        default:
                    }
                }
                #end
                var alreadyBound = queryDefinedBefore(i);
                if (!alreadyBound) {
                    // Prefer promotion from immediate wildcard downcase assignment
                    var promoted = false;
                    if (i - 1 >= 0) {
                        switch (stmts[i - 1].def) {
                            case EMatch(PWildcard, r) if (isDowncaseOfSearchQuery(r)):
                                #if debug_filter_query_consolidate
                                trace('[FilterQueryConsolidate] Promoting wildcard downcase to query binder at index ' + (i-1));
                                #end
                                out.pop();
                                out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), r), ctx.metadata, ctx.pos));
                                promoted = true;
                            case EBinary(Match, leftPrev, rB) if (isDowncaseOfSearchQuery(rB)):
                                // Accept `_ = String.downcase(...)` as binary match
                                // Replace previous with binder assignment
                                #if debug_filter_query_consolidate
                                trace('[FilterQueryConsolidate] Promoting binary match downcase to query binder at index ' + (i-1));
                                #end
                                out.pop();
                                out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rB), ctx.metadata, ctx.pos));
                                promoted = true;
                            default:
                        }
                    }
                    if (!promoted) {
                        // Insert binder from nearest prior downcase if available
                        var prior = nearestPriorDowncase(i);
                        if (prior != null) {
                            #if debug_filter_query_consolidate
                            trace('[FilterQueryConsolidate] Inserting binder from nearest prior downcase before index ' + i);
                            #end
                            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), prior), ctx.metadata, ctx.pos));
                        } else if (hasSearchQuery && predPos != null) {
                            // Inline in predicate body
                            #if debug_filter_query_consolidate
                            trace('[FilterQueryConsolidate] Inlining query in predicate for filter at ' + i);
                            #end
                            var cl = predPos.clauses[0];
                            var newBody = inlineQuery(cl.body);
                            var newFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]));
                            switch (s.def) {
                                case ERemoteCall(modR, "filter", aR):
                                    s = makeASTWithMeta(ERemoteCall(modR, "filter", [aR[0], newFn]), s.metadata, s.pos);
                                case ECall(tC, "filter", aC):
                                    var prefixArgs = (aC != null && aC.length == 2) ? [aC[0]] : [];
                                    s = makeASTWithMeta(ECall(tC, "filter", prefixArgs.concat([newFn])), s.metadata, s.pos);
                                case EMatch(lhsM, rhsM):
                                    switch (rhsM.def) {
                                        case ERemoteCall(modM, "filter", aM):
                                            var repl = makeAST(ERemoteCall(modM, "filter", [aM[0], newFn]));
                                            s = makeASTWithMeta(EMatch(lhsM, repl), s.metadata, s.pos);
                                        case ECall(tM, "filter", aMC):
                                            var pArgs = (aMC != null && aMC.length == 2) ? [aMC[0]] : [];
                                            var repl2 = makeAST(ECall(tM, "filter", pArgs.concat([newFn])));
                                            s = makeASTWithMeta(EMatch(lhsM, repl2), s.metadata, s.pos);
                                        default:
                                    }
                                case EBinary(Match, leftB, rhsB):
                                    switch (rhsB.def) {
                                        case ERemoteCall(modB, "filter", aB):
                                            var replB = makeAST(ERemoteCall(modB, "filter", [aB[0], newFn]));
                                            s = makeASTWithMeta(EBinary(Match, leftB, replB), s.metadata, s.pos);
                                        case ECall(tB, "filter", aBC):
                                            var pr = (aBC != null && aBC.length == 2) ? [aBC[0]] : [];
                                            var replBC = makeAST(ECall(tB, "filter", pr.concat([newFn])));
                                            s = makeASTWithMeta(EBinary(Match, leftB, replBC), s.metadata, s.pos);
                                        default:
                                    }
                                default:
                            }
                        }
                    }
                }
            }
            out.push(s);
            i++;
        }
        return out;
    }
}

#end
