package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - In block-like contexts (EBlock/EDo/EFn bodies), underscore local assignment targets
 *   when they are not referenced later in the same block. Also handles nested assignments
 *   inside `outer = (inner = expr)` by underscoring `inner` when unused.
 *
 * WHY
 * - Removes warnings for throwaway temps (e.g., g, g3) created by intermediate rewrites.
 */
/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - Late hygiene sweep that underscores local assignment targets not referenced later
 *   and collapses nested chains `outer = (inner = expr)` where safe.
 *
 * WHY
 * - Eliminates throwaway temps (g/g3/thisN) produced by intermediate rewrites that
 *   otherwise cause WAE. Collapsing nested chains produces cleaner, idiomatic code.
 *
 * HOW
 * - For EBlock/EDo/EFn bodies, scan each statement, detect nested matches, and either
 *   collapse or underscore unused binders. Variable usage checks look through common
 *   constructs to avoid false positives/negatives.
 *
 * EXAMPLES
 * Elixir (before):
 *   g = compute()
 *   :ok
 * Elixir (after):
 *   _g = compute()
 *   :ok
 */
class LocalAssignUnderscoreLateTransforms {
    static function referencesVar(n: ElixirAST, name: String): Bool {
        var found = false;
        function visit(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EString(s):
                    // Consider identifiers inside string interpolation as references
                    try {
                        var block = new EReg("\\#\\{([^}]*)\\}", "g");
                        var pos = 0;
                        while (block.matchSub(s, pos)) {
                            var inner = block.matched(1);
                            var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
                            var tpos = 0;
                            while (tok.matchSub(inner, tpos)) {
                                var id = tok.matched(0);
                                if (id == name) { found = true; break; }
                                tpos = tok.matchedPos().pos + tok.matchedPos().len;
                            }
                            if (found) break;
                            pos = block.matchedPos().pos + block.matchedPos().len;
                        }
                    } catch (e) {}
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ERemoteCall(m, _, as): visit(m); if (as != null) for (a in as) visit(a);
                case ECall(t, _, as2): if (t != null) visit(t); if (as2 != null) for (a in as2) visit(a);
                case EBlock(es): for (e in es) visit(e);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(cond, cs): visit(cond); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                default:
            }
        }
        visit(n);
        return found;
    }
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock(processStmts(stmts)), n.metadata, n.pos);
                case EDo(stmts2): makeASTWithMeta(EDo(processStmts(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(processStmts(ss)), b.metadata, b.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(processStmts(ss2)), b.metadata, b.pos);
                            default: b;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * processStmts
     *
     * WHAT
     * - Processes a statement list, applying nested assign collapse and underscore
     *   of unused local assignment targets.
     */
    static function processStmts(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var usage = OptimizedVarUseAnalyzer.build(stmts);
        for (i in 0...stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case EBinary(Match, left, rhs):
                    // Nested: outer = (inner = expr) → underscore inner if unused later
                    var collapse = false;
                    var collapsedExpr:Null<ElixirAST> = null;
                    var newRhs = switch (rhs.def) {
                        case EBinary(Match, leftInner, expr):
                            var innerName:Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                            if (innerName != null && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, innerName)) {
                                // Collapse nested: outer = (inner = expr) -> outer = expr
                                collapse = true;
                                collapsedExpr = expr;
                                rhs;
                            } else rhs;
                        default: rhs;
                    };
                    // Left var unused later → underscore
                    var leftName:Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                    var newLeft = left;
                    if (leftName != null && leftName == "query" && filterPredicateUsesQueryLater(stmts, i + 1)) {
                        // keep as named binder
                    } else {
                        // Conservative: do not rename non-underscore binders here. Leave to dedicated underscore passes.
                        newLeft = left;
                    }
                    if (collapse && collapsedExpr != null) {
                        #if debug_hygiene
                        #end
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, collapsedExpr), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, newRhs), s.metadata, s.pos));
                    }
                case EMatch(pat, rhs):
                    var collapseNested = false;
                    var collapsedExprInner:Null<ElixirAST> = null;
                    var newRhsInner = switch (rhs.def) {
                        case EBinary(Match, innerLeft, rhsExprInner):
                            var innerName:Null<String> = switch (innerLeft.def) { case EVar(n): n; default: null; };
                            if (innerName != null && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, innerName)) {
                                collapseNested = true; collapsedExprInner = rhsExprInner; rhs;
                            } else rhs;
                        case EMatch(innerPattern, rhsExprCandidate):
                            var innerNameCandidate:Null<String> = switch (innerPattern) { case PVar(n3): n3; default: null; };
                            if (innerNameCandidate != null && !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, innerNameCandidate)) {
                                collapseNested = true; collapsedExprInner = rhsExprCandidate; rhs;
                            } else rhs;
                        default: rhs;
                    };
                    var leftPatternName:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                    var newPat = pat;
                    if (leftPatternName != null && leftPatternName == "query" && filterPredicateUsesQueryLater(stmts, i + 1)) {
                        // keep as named binder
                    } else {
                        // Conservative: no rename of non-underscore binders at this stage.
                        newPat = pat;
                    }
                    if (collapseNested && collapsedExprInner != null) {
                        out.push(makeASTWithMeta(EMatch(newPat, collapsedExprInner), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EMatch(newPat, newRhsInner), s.metadata, s.pos));
                    }
                default:
                    out.push(s);
            }
        }
        return out;
    }

    // usage analysis delegated to VarUseAnalyzer

    static function hasPinnedVarInBlock(stmts: Array<ElixirAST>, startIdx: Int, name: String): Bool {
        if (name == null || name.length == 0) return false;
        var found = false;
        inline function snakeCase(n:String):String {
            if (n == null || n.length == 0) return n;
            var out = new StringBuf();
            for (i in 0...n.length) {
                var ch = n.charAt(i);
                var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
                if (isUpper && i > 0) out.add("_");
                out.add(ch.toLowerCase());
            }
            return out.toString();
        }
        inline function camelCase(s:String):String {
            if (s == null || s.length == 0) return s;
            var parts = s.split("_");
            if (parts.length == 1) return s;
            var out = new StringBuf();
            for (i in 0...parts.length) {
                var p = parts[i];
                if (p.length == 0) continue;
                if (i == 0) out.add(p); else out.add(p.charAt(0).toUpperCase() + p.substr(1));
            }
            return out.toString();
        }
        var candidates = [name];
        var sn = snakeCase(name);
        if (sn != null && sn != name) candidates.push(sn);
        var cc = camelCase(name);
        if (cc != null && cc != name && cc != sn) candidates.push(cc);
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EPin(inner):
                    switch (inner.def) {
                        case EVar(v):
                            for (c in candidates) if (v == c) { found = true; return; }
                        default:
                    }
                case EBlock(ss): for (s in ss) scan(s);
                case EDo(ss2): for (s in ss2) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(tgt, _, args2): if (tgt != null) scan(tgt); for (a in args2) scan(a);
                case ERemoteCall(tgt2, _, args3): scan(tgt2); for (a in args3) scan(a);
                case ECase(expr, cs): scan(expr); for (c in cs) scan(c.body);
                case ERaw(code) if (code != null):
                    for (c in candidates) {
                        var needle = '^(' + c + ')';
                        if (code.indexOf(needle) != -1) { found = true; break; }
                    }
                default:
            }
        }
        for (j in startIdx...stmts.length) { scan(stmts[j]); if (found) return true; }
        return false;
    }

    static function hasPinnedVarInEctoWhere(stmts: Array<ElixirAST>, startIdx: Int, name: String, ?assignVarId: Null<Int>): Bool {
        if (name == null || name.length == 0) return false;
        var found = false;
        inline function snakeCase(n:String):String {
            if (n == null || n.length == 0) return n;
            var out = new StringBuf();
            for (i in 0...n.length) {
                var ch = n.charAt(i);
                var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
                if (isUpper && i > 0) out.add("_");
                out.add(ch.toLowerCase());
            }
            return out.toString();
        }
        inline function camelCase(s:String):String {
            if (s == null || s.length == 0) return s;
            var parts = s.split("_");
            if (parts.length == 1) return s;
            var out = new StringBuf();
            for (i in 0...parts.length) {
                var p = parts[i];
                if (p.length == 0) continue;
                if (i == 0) out.add(p); else out.add(p.charAt(0).toUpperCase() + p.substr(1));
            }
            return out.toString();
        }
        var candidates = [name];
        var sn = snakeCase(name);
        if (sn != null && sn != name) candidates.push(sn);
        var cc = camelCase(name);
        if (cc != null && cc != name && cc != sn) candidates.push(cc);
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERemoteCall(mod, func, args) if (func == "where" && args != null && args.length >= 2):
                    var cond = args[args.length - 1];
                    var innerFound = false;
                    ElixirASTTransformer.transformNode(cond, function(x: ElixirAST): ElixirAST {
                        if (innerFound) return x;
                        switch (x.def) {
                            case EPin(inner):
                                var u = switch (inner.def) { case EParen(p): p; default: inner; };
                                switch (u.def) {
                                    case EVar(v):
                                        for (c in candidates) if (v == c) { innerFound = true; break; }
                                        if (!innerFound && assignVarId != null && u.metadata != null && u.metadata.sourceVarId != null) {
                                            if (u.metadata.sourceVarId == assignVarId) innerFound = true;
                                        }
                                        return x;
                                    default: return x;
                                }
                            default: return x;
                        }
                    });
                    if (innerFound) found = true;
                case ERaw(code) if (code != null):
                    var containsWhere = (code.indexOf("where(") != -1) || (code.indexOf("Ecto.Query.where(") != -1);
                    if (containsWhere) {
                        for (c in candidates) {
                            var needle = '^(' + c + ')';
                            if (code.indexOf(needle) != -1) { found = true; break; }
                        }
                    }
                case EBlock(ss): for (s in ss) scan(s);
                case EDo(ss2): for (s in ss2) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(tgt, _, args2): if (tgt != null) scan(tgt); for (a in args2) scan(a);
                case ERemoteCall(tgt2, _, args3): scan(tgt2); for (a in args3) scan(a);
                case ECase(expr, cs): scan(expr); for (c in cs) scan(c.body);
                default:
            }
        }
        for (j in startIdx...stmts.length) {
            scan(stmts[j]);
            if (found) return true;
        }
        return false;
    }

    static function filterPredicateUsesQueryLater(stmts: Array<ElixirAST>, startIdx: Int): Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }
        function hasQueryInEFnBody(fn: ElixirAST): Bool {
            var inner = false;
            ElixirASTTransformer.transformNode(fn, function(x: ElixirAST): ElixirAST {
                if (inner) return x;
                switch (x.def) {
                    case EVar(nm) if (nm == "query"): inner = true; return x;
                    case ERaw(code) if (code != null):
                        var start = 0;
                        while (!inner) {
                            var idx = code.indexOf("query", start);
                            if (idx == -1) break;
                            var before = idx > 0 ? code.substr(idx - 1, 1) : null;
                            var afterIdx = idx + 5;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { inner = true; break; }
                            start = idx + 5;
                        }
                        return x;
                    default: return x;
                }
            });
            return inner;
        }
        function scan(x: ElixirAST): Void {
            if (x == null || x.def == null || found) return;
            switch (x.def) {
                case ERaw(code) if (code != null):
                    if (code.indexOf('Enum.filter(') != -1 && rawContainsIdent(code, 'query')) found = true;
                case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                    switch (args[1].def) { case EFn(cs) if (cs.length == 1): if (hasQueryInEFnBody(args[1])) found = true; default: }
                case ECall(_, "filter", args2) if (args2 != null && args2.length >= 1):
                    var pred = args2[args2.length - 1];
                    switch (pred.def) { case EFn(cs2) if (cs2.length == 1): if (hasQueryInEFnBody(pred)) found = true; default: }
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
}

#end
