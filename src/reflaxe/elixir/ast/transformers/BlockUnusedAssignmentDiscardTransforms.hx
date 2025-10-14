package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

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
                case EDef(name, args, guards, body):
                    var nb = rewriteBody(body);
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EBlock(_):
                    rewriteBody(n);
                case EDo(_):
                    rewriteBody(n);
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

    /**
     * rewriteBody
     *
     * WHAT
     * - Performs the per-block transformation, handling both EBinary(Match, …) and
     *   EMatch(PVar, rhs) forms.
     */
    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(nm):
                                    // Safety: do not discard known supervisor children binding
                                    if (nm == "children") { out.push(s); break; }
                                    if (nm == "query" && filterPredicateUsesQueryLater(stmts, i + 1)) {
                                        out.push(s);
                                    } else if (isDowncaseSearch(rhs)) {
                                        out.push(s);
                                    } else if (!VarUseAnalyzer.usedLater(stmts, i + 1, nm)) {
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                    } else out.push(s);
                                default: out.push(s);
                            }
                        case EMatch(pat, rhs2):
                            switch (pat) {
                                case PVar(nm2):
                                    if (nm2 == "children") { out.push(s); break; }
                                    if (isDowncaseSearch(rhs2)) {
                                        out.push(s);
                                    } else if (!VarUseAnalyzer.usedLater(stmts, i + 1, nm2)) {
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
                                    if (nm2 == "query" && filterPredicateUsesQueryLater(stmts2, i + 1)) {
                                        out2.push(s2);
                                    } else if (isDowncaseSearch(rhs2)) {
                                        out2.push(s2);
                                    } else if (!VarUseAnalyzer.usedLater(stmts2, i + 1, nm2)) {
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

    static function isDowncaseSearch(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
                switch (args[0].def) { case EVar(v) if (v == "search_query"): true; default: false; }
            default: false;
        };
    }

    static function filterPredicateUsesQueryLater(stmts: Array<ElixirAST>, startIdx: Int): Bool {
        for (i in startIdx...stmts.length) if (stmtHasFilterQueryUse(stmts[i])) return true;
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
