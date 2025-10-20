package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;
import StringTools;

/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In function bodies (EDef → EBlock), rewrite `var = expr` to `_ = expr` when `var` is not
 *   referenced later in the same block.
 */
/**
 * BlockUnusedAssignmentDiscardTransforms
 *
 * WHAT
 * - In block-like contexts (EDef/EFn/EBlock/EDo), rewrite `var = expr` to `_ = expr`
 *   when `var` is not referenced later in the same block. Also supports `EMatch(PVar, rhs)`.
 *
 * WHY
 * - Removes throwaway temps introduced by lowerings without changing semantics. This
 *   reduces warnings and enables WAE=0 for generated LiveView helpers.
 *
 * HOW
 * - For each block, forward-scan for later usage (including ERaw, map/keyword, struct
 *   update targets) before deciding to discard the assignment target.
 *
 * EXAMPLES
 * Before: this1 = Ecto.Changeset.change(cs); ... (no later use of this1)
 * After:  _ = Ecto.Changeset.change(cs)
 */
class BlockUnusedAssignmentDiscardTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresenceModule(name, n)):
                    // Skip this hygiene pass inside Presence modules to preserve effectful scaffolding
                    n;
                case EDefmodule(name, doBlock) if (looksLikePresenceModule(name, n)):
                    n;
                case EDef(name, args, guards, body):
                    var nb = rewriteBody(body, name == "changeset");
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EBlock(_):
                    rewriteBody(n);
                case EDo(_):
                    rewriteBody(n);
                case EIf(cond, then_, else_):
                    var newThen = rewriteBody(then_);
                    var newElse = else_ != null ? rewriteBody(else_) : null;
                    makeASTWithMeta(EIf(cond, newThen, newElse), n.metadata, n.pos);
                case ECase(expr, clauses):
                    var newClauses:Array<ECaseClause> = [];
                    for (cl in clauses) newClauses.push({
                        pattern: cl.pattern,
                        guard: cl.guard,
                        body: rewriteBody(cl.body)
                    });
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        newClauses.push({ args: cl.args, guard: cl.guard, body: rewriteBody(b) });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresenceModule(name:String, node:ElixirAST):Bool {
        if (node != null && node.metadata != null && node.metadata.isPresence == true) return true;
        if (name == null) return false;
        return StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web.Presence");
    }

    /**
     * rewriteBody
     *
     * WHAT
     * - Performs the per-block transformation, handling both EBinary(Match, …) and
     *   EMatch(PVar, rhs) forms.
     */
    static function rewriteBody(body: ElixirAST, ?inChangeset: Bool = false): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                // Helper to detect presence of HEEx (~H) usage in the tail of the block
                function hasHeexFrom(start:Int):Bool {
                    var found = false;
                    for (k in start...stmts.length) {
                        switch (stmts[k].def) {
                            case ESigil(type, _, _) if (type == "H"): found = true;
                            case ERaw(code) if (code != null && code.indexOf("~H\"") != -1): found = true;
                            default:
                        }
                        if (found) break;
                    }
                    return found;
                }
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(nm):
                                    // Safety: do not discard known supervisor children binding
                                    if (nm == "children") { out.push(s); break; }
                                    // Do not discard assigns anywhere; render/1 and ~H rely on it implicitly
                                    if (nm == "assigns") { out.push(s); break; }
                                    // Preserve effectful Presence track/update/untrack assignment even if not referenced later
                                    if (isPresenceEffectCall(rhs)) { out.push(s); break; }
                                    if (nm == "query" && filterPredicateUsesQueryLater(stmts, i + 1)) {
                                        out.push(s);
                                    } else if (isDowncaseSearch(rhs)) {
                                        out.push(s);
                                    } else if (
                                            !(inChangeset && rhsContainsChangesetCall(rhs))
                                            && !VarUseAnalyzer.usedLater(stmts, i + 1, nm)
                                            && !rawIdentifierUsedLater(stmts, i + 1, nm)
                                            && !exprReferencesName(rhs, nm)
                                            && !hasPinnedVarInEctoWhere(stmts, i + 1, nm, s.metadata != null ? s.metadata.varId : null)
                                            && !hasPinnedVarInBlock(stmts, i + 1, nm)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        case EMatch(pat, rhs2):
                            switch (pat) {
                                case PVar(nm2):
                                    if (nm2 == "children") { out.push(s); break; }
                                    if (nm2 == "assigns") { out.push(s); break; }
                                    if (isPresenceEffectCall(rhs2)) { out.push(s); break; }
                                    if (isDowncaseSearch(rhs2)) {
                                        out.push(s);
                                    } else if (
                                            !(inChangeset && rhsContainsChangesetCall(rhs2))
                                            && !VarUseAnalyzer.usedLater(stmts, i + 1, nm2)
                                            && !rawIdentifierUsedLater(stmts, i + 1, nm2)
                                            && !exprReferencesName(rhs2, nm2)
                                            && !hasPinnedVarInEctoWhere(stmts, i + 1, nm2, s.metadata != null ? s.metadata.varId : null)
                                            && !hasPinnedVarInBlock(stmts, i + 1, nm2)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                // Treat EDo like EBlock for hygiene
                var out2:Array<ElixirAST> = [];
                for (i in 0...stmts2.length) {
                    var s2 = stmts2[i];
                    switch (s2.def) {
                        case EBinary(Match, left2, rhs2):
                            switch (left2.def) {
                                case EVar(nm2):
                                    // Preserve assigns rebinds in any context
                                    if (nm2 == "assigns") { out2.push(s2); break; }
                                    if (nm2 == "query" && filterPredicateUsesQueryLater(stmts2, i + 1)) {
                                        out2.push(s2);
                                    } else if (isDowncaseSearch(rhs2)) {
                                        out2.push(s2);
                                    } else if (
                                            !(inChangeset && rhsContainsChangesetCall(rhs2))
                                            && !VarUseAnalyzer.usedLater(stmts2, i + 1, nm2)
                                            && !rawIdentifierUsedLater(stmts2, i + 1, nm2)
                                            && !exprReferencesName(rhs2, nm2)) {
                                        out2.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s2.metadata, s2.pos));
                                    } else out2.push(s2);
                                default: out2.push(s2);
                            }
                        default:
                            out2.push(s2);
                    }
                }
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function rhsContainsChangesetCall(e: ElixirAST): Bool {
        var found = false;
        function scan(n: ElixirAST): Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case ERemoteCall(mod, _, _):
                    switch (mod.def) { case EVar(m) if (m == "Ecto.Changeset"): found = true; default: }
                case ERaw(code): if (code != null && code.indexOf("Ecto.Changeset.") != -1) found = true;
                case ECall(t, _, as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                case ERemoteCall(t2, _, as2): scan(t2); if (as2 != null) for (a2 in as2) scan(a2);
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case EBlock(ss): for (s in ss) scan(s);
                default:
            }
        }
        scan(e);
        return found;
    }

    static function exprReferencesName(e: ElixirAST, name: String): Bool {
        var found = false;
        function visit(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(n) if (n == name): found = true;
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(t, _, args): if (t != null) visit(t); if (args != null) for (a in args) visit(a);
                case ERemoteCall(m, _, args2): visit(m); if (args2 != null) for (a in args2) visit(a);
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(cond, cs): visit(cond); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                default:
            }
        }
        visit(e);
        return found;
    }

    static function isPresenceEffectCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(mod)}, func, _):
                // API-based, not app-specific: match Presence module and known mutating calls
                var isPresence = (mod == "Phoenix.Presence") || StringTools.endsWith(mod, ".Presence") || (mod == "Presence");
                if (!isPresence) false else (func == "track" || func == "update" || func == "untrack");
            default:
                false;
        };
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
                    // Accept both qualified and imported where/2; mod may be EVar("Ecto.Query") or other
                    var cond = args[args.length - 1];
                    // Look for EPin(EVar(name)) anywhere in cond
                    var innerFound = false;
                    ElixirASTTransformer.transformNode(cond, function(x: ElixirAST): ElixirAST {
                        if (innerFound) return x;
                        switch (x.def) {
                            case EPin(inner):
                                // unwrap parentheses
                                var u = switch (inner.def) { case EParen(p): p; default: inner; };
                                switch (u.def) {
                                    case EVar(v):
                                        for (c in candidates) if (v == c) { innerFound = true; break; }
                                        // Also allow varId matching when available
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
                    // Conservative check: where(... ^(name)) pattern in raw code
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

    static function isDowncaseSearch(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
                switch (args[0].def) { case EVar(v) if (v == "search_query"): true; default: false; }
            default: false;
        };
    }

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

    static function filterPredicateUsesQueryLater(stmts: Array<ElixirAST>, startIdx: Int): Bool {
        for (i in startIdx...stmts.length) if (stmtHasFilterQueryUse(stmts[i])) return true;
        return false;
    }

    static function rawIdentifierUsedLater(stmts: Array<ElixirAST>, startIdx: Int, name: String): Bool {
        if (name == null || name.length == 0) return false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }
        for (i in startIdx...stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case ERaw(code) if (code != null):
                    var idx = 0;
                    while (true) {
                        idx = code.indexOf(name, idx);
                        if (idx == -1) break;
                        var before = idx > 0 ? code.substr(idx - 1, 1) : null;
                        var afterIdx = idx + name.length;
                        var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                        if (!isIdentChar(before) && !isIdentChar(after)) return true;
                        idx = afterIdx;
                    }
                case EBlock(ss): if (rawIdentifierUsedLater(ss, 0, name)) return true;
                case EDo(ss2): if (rawIdentifierUsedLater(ss2, 0, name)) return true;
                case EIf(c,t,e):
                    // scan nested branches conservatively
                    var tmpS = [c, t].concat(e != null ? [e] : []);
                    if (rawIdentifierUsedLater(tmpS, 0, name)) return true;
                default:
            }
        }
        return false;
    }

    static function stmtHasFilterQueryUse(n: ElixirAST): Bool {
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
        scan(n);
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
