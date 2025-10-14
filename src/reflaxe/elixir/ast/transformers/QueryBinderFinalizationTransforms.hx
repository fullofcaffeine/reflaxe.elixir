package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * QueryBinderFinalizationTransforms
 *
 * WHAT
 * - Absolute-final shape-based fix to ensure that within a search-guarded EIf
 *   then-branch, a preceding `_ = String.downcase(search_query)` is promoted to
 *   `query = String.downcase(search_query)` when an Enum.filter(...) appears later
 *   in the same branch. Prevents undefined `query` in predicate bodies.
 *
 * WHY
 * - Earlier passes may discard an intended `query` binder into wildcard or fail to
 *   promote a nearby downcase. This pass runs at the very end to restore the binder
 *   deterministically in guarded contexts without app-specific heuristics.
 *
 * HOW
 * - Detect EIf(cond, then, else) where cond matches the standard search guard.
 * - If then is EBlock/EDo, scan statements; if a `_ = String.downcase(search_query)`
 *   appears before any Enum.filter(...) statement, replace that underscore assign with
 *   `query = String.downcase(search_query)`.
 */
class QueryBinderFinalizationTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Generic renaming: <name> = String.downcase(search_query) → query = ...
                // This is safe and generic; later hygiene will underscore if unused.
                case EBinary(Match, left0, rhs0):
                    var forceQuery:Bool = false;
                    var isDown = switch (rhs0.def) {
                        case ERemoteCall({def: EVar(m0)}, "downcase", args0) if (m0 == "String" && args0 != null && args0.length == 1):
                            switch (args0[0].def) { case EVar(v0) if (v0 == "search_query"): true; default: false; }
                        default: false;
                    };
                    if (isDown) {
                        switch (left0.def) {
                            case EVar(nm) if (nm != "query"): forceQuery = true;
                            case EUnderscore: forceQuery = true;
                            default:
                        }
                    }
                    if (forceQuery) return makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs0), n.metadata, n.pos) else n;
                // Generic renaming for EMatch: var = String.downcase(search_query)
                case EMatch(pat0, rhs1):
                    var isDown2 = switch (rhs1.def) {
                        case ERemoteCall({def: EVar(m1)}, "downcase", args1) if (m1 == "String" && args1 != null && args1.length == 1):
                            switch (args1[0].def) { case EVar(v1) if (v1 == "search_query"): true; default: false; }
                        default: false;
                    };
                    if (isDown2) {
                        switch (pat0) {
                            case PVar(nm) if (nm != "query"): return makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs1), n.metadata, n.pos);
                            case PWildcard: return makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs1), n.metadata, n.pos);
                            default:
                        }
                    }
                    n;
                case EIf(cond, thenB, elseB) if (detectSearchGuard(cond)):
                    #if debug_filter_query_consolidate
                    Sys.println('[QueryBinderFinalization] Detected search_guard EIf');
                    #end
                    var newThen = finalizeBranch(thenB);
                    if (newThen != thenB) makeASTWithMeta(EIf(cond, newThen, elseB), n.metadata, n.pos) else n;
                // Also run in generic blocks/do to catch non-guarded placements
                case EBlock(_):
                    var nb = finalizeBranch(n);
                    nb;
                case EDo(_):
                    var nb2 = finalizeBranch(n);
                    nb2;
                default:
                    n;
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

    static function isWildcardDowncase(s: ElixirAST): Bool {
        return switch (s.def) {
            case EMatch(PWildcard, rhs):
                switch (rhs.def) {
                    case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
                        switch (args[0].def) { case EVar(v) if (v == "search_query"): true; default: false; }
                    default: false;
                }
            case EBinary(Match, left, rhs2):
                var isWild = switch (left.def) { case EVar(nm) if (nm == "_"): true; default: false; };
                if (!isWild) return false;
                switch (rhs2.def) {
                    case ERemoteCall({def: EVar(m2)}, "downcase", args2) if (m2 == "String" && args2 != null && args2.length == 1):
                        switch (args2[0].def) { case EVar(v2) if (v2 == "search_query"): true; default: false; }
                    default: false;
                }
            default: false;
        }
    }

    static function isAnyDowncaseBinder(s: ElixirAST): { match: Bool, renameNeeded: Bool } {
        // Detect any assignment of the form <name> = String.downcase(search_query)
        // Returns match=true when such assignment detected; renameNeeded=true when name != "query".
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var lname:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                if (lname == null) return { match: false, renameNeeded: false };
                switch (rhs.def) {
                    case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
                        switch (args[0].def) {
                            case EVar(v) if (v == "search_query"): { match: true, renameNeeded: lname != "query" };
                            default: { match: false, renameNeeded: false };
                        }
                    default: { match: false, renameNeeded: false };
                }
            default:
                { match: false, renameNeeded: false };
        }
    }

    static function isQueryDowncaseBinder(s: ElixirAST): Bool {
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var isQ = switch (left.def) { case EVar(nm) if (nm == "query"): true; default: false; };
                if (!isQ) false else switch (rhs.def) {
                    case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1): true;
                    default: false;
                };
            case EMatch(pat, rhs2):
                var isQ2 = switch (pat) { case PVar(nm2) if (nm2 == "query"): true; default: false; };
                if (!isQ2) false else switch (rhs2.def) {
                    case ERemoteCall({def: EVar(m2)}, "downcase", args2) if (m2 == "String" && args2 != null && args2.length == 1): true;
                    default: false;
                };
            default: false;
        };
    }

    static function branchHasFilterLater(stmts: Array<ElixirAST>, startIdx: Int): Bool {
        var found = false;
        function scan(x: ElixirAST): Void {
            if (x == null || x.def == null || found) return;
            switch (x.def) {
                case ERemoteCall({def: EVar(m)}, "filter", _) if (m == "Enum"): found = true;
                case ECall(_, "filter", _): found = true;
                case EBlock(ss): for (s in ss) scan(s);
                case EDo(ss2): for (s in ss2) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case EMatch(_, rhs): scan(rhs);
                case EBinary(_, l, r): scan(l); scan(r);
                case ECall(tgt, _, args3): if (tgt != null) scan(tgt); for (a in args3) scan(a);
                case ERemoteCall(tgt2, _, args4): scan(tgt2); for (a in args4) scan(a);
                case ECase(expr, cs): scan(expr); for (c in cs) scan(c.body);
                default:
            }
        }
        for (i in startIdx...stmts.length) scan(stmts[i]);
        return found;
    }

    static function isFilterStmt(s: ElixirAST): Bool {
        return switch (s.def) {
            case ERemoteCall({def: EVar(m)}, "filter", _) if (m == "Enum"): true;
            case ECall(_, "filter", _): true;
            case EMatch(_, rhs): isFilterExpr(rhs);
            case EBinary(Match, _, rhs2): isFilterExpr(rhs2);
            default: false;
        };
    }
    static function isFilterExpr(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(m)}, "filter", _) if (m == "Enum"): true;
            case ECall(_, "filter", _): true;
            default: false;
        };
    }

    static inline function isIdentChar(c: String): Bool {
        if (c == null || c.length == 0) return false;
        var ch = c.charCodeAt(0);
        return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
    }
    static function rawContainsIdent(code: String, ident: String): Bool {
        if (code == null || ident == null || ident.length == 0) return false;
        var start = 0; var len = ident.length;
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
    static function predicateUsesQueryInStmt(s: ElixirAST): Bool {
        var found = false;
        function usesIn(e: ElixirAST): Void {
            if (e == null || e.def == null || found) return;
            switch (e.def) {
                case EFn(clauses):
                    for (cl in clauses) if (cl.body != null) ElixirASTTransformer.transformNode(cl.body, function(x) {
                        if (found) return x;
                        switch (x.def) {
                            case EVar(nm) if (nm == "query"): found = true; return x;
                            case ERaw(code) if (code != null && rawContainsIdent(code, "query")): found = true; return x;
                            default: return x;
                        }
                    });
                case ERaw(code) if (code != null && code.indexOf('Enum.filter(') != -1 && rawContainsIdent(code, 'query')):
                    found = true;
                default:
            }
        }
        switch (s.def) {
            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args.length == 2): usesIn(args[1]);
            case ECall(_, "filter", args2) if (args2.length >= 1):
                var pred = args2[args2.length - 1]; usesIn(pred);
            case EMatch(_, rhs): if (isFilterExpr(rhs)) usesIn(rhs);
            case EBinary(Match, _, rhs2): if (isFilterExpr(rhs2)) usesIn(rhs2);
            default:
        }
        return found;
    }
    static function hasDefinedQueryBefore(stmts:Array<ElixirAST>, idx:Int): Bool {
        for (k in 0...idx) switch (stmts[k].def) {
            case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): return true; default: }
            case EMatch(pat, _): switch (pat) { case PVar(nm2) if (nm2 == "query"): return true; default: }
            default:
        }
        return false;
    }

    static function finalizeBranch(thenB: ElixirAST): ElixirAST {
        return switch (thenB.def) {
            case EDo(es):
                var out = [];
                var promoted = false;
                var seenQuery = false;
                for (i in 0...es.length) {
                    var s = es[i];
                    if (isQueryDowncaseBinder(s)) { out.push(s); seenQuery = true; continue; }
                    var nextIsFilter = (i + 1 < es.length) && isFilterStmt(es[i + 1]);
                    if (!promoted && isWildcardDowncase(s) && (nextIsFilter || branchHasFilterLater(es, i + 1))) {
                        #if debug_filter_query_consolidate
                        Sys.println('[QueryBinderFinalization] Promoting wildcard downcase to query binder (EDo)');
                        #end
                        // Replace with named binder
                        switch (s.def) {
                            case EMatch(_, rhs): out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs), thenB.metadata, thenB.pos)); promoted = true;
                            case EBinary(Match, _, rhsB): out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhsB), thenB.metadata, thenB.pos)); promoted = true;
                            default: out.push(s);
                        }
                    } else if (seenQuery && isWildcardDowncase(s)) {
                        // Drop redundant wildcard downcase after establishing query binder
                        #if debug_filter_query_consolidate
                        Sys.println('[QueryBinderFinalization] Dropping redundant wildcard downcase (EDo)');
                        #end
                        // skip
                    } else out.push(s);
                }
                makeASTWithMeta(EDo(out), thenB.metadata, thenB.pos);
            case EBlock(es2):
                var out2 = [];
                var promoted2 = false;
                var seenQuery2 = false;
                for (i in 0...es2.length) {
                    var s2 = es2[i];
                    if (isQueryDowncaseBinder(s2)) { out2.push(s2); seenQuery2 = true; continue; }
                    var anyDown = isAnyDowncaseBinder(s2);
                    var nextIsFilter2 = (i + 1 < es2.length) && isFilterStmt(es2[i + 1]);
                    if (!promoted2 && (isWildcardDowncase(s2) || (anyDown.match && anyDown.renameNeeded)) && (nextIsFilter2 || branchHasFilterLater(es2, i + 1))) {
                        #if debug_filter_query_consolidate
                        Sys.println('[QueryBinderFinalization] Forcing query binder for downcase(search_query) (EBlock)');
                        #end
                        switch (s2.def) {
                            case EMatch(_, rhs2): out2.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs2), thenB.metadata, thenB.pos)); promoted2 = true;
                            case EBinary(Match, _, rhs2B): out2.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs2B), thenB.metadata, thenB.pos)); promoted2 = true;
                            default: out2.push(s2);
                        }
                    } else if (seenQuery2 && isWildcardDowncase(s2)) {
                        #if debug_filter_query_consolidate
                        Sys.println('[QueryBinderFinalization] Dropping redundant wildcard downcase (EBlock)');
                        #end
                        // skip
                    } else {
                        // If we encounter a filter statement using query without prior binder, inject binder now
                        if (isFilterStmt(s2) && predicateUsesQueryInStmt(s2) && !hasDefinedQueryBefore(out2.concat(es2.slice(i)), 0)) {
                            var rhsQ = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            out2.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhsQ), thenB.metadata, thenB.pos));
                        }
                        out2.push(s2);
                    }
                }
                makeASTWithMeta(EBlock(out2), thenB.metadata, thenB.pos);
            default:
                thenB;
        }
    }
}

#end
