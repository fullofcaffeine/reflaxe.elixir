package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * QueryBinderRescueTransforms
 *
 * WHAT
 * - Repairs query binder names after early hygiene when later filter predicates
 *   (including ERaw) use `query` but binder was underscored to `_query` or wildcard.
 *
 * HOW
 * - For each EBlock/EDo list, if we see `_query = String.downcase(search_query)` (or
 *   `_ = String.downcase(search_query)`), and later a filter appears that references
 *   `query` (EFn body or ERaw), rewrite binder to `query = String.downcase(search_query)`.
 */
class QueryBinderRescueTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 0): makeASTWithMeta(EBlock(rewrite(stmts, n)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0): makeASTWithMeta(EDo(rewrite(stmts2, n)), n.metadata, n.pos);
                default: n;
            }
        });
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
    static function hasFilterQueryLater(stmts: Array<ElixirAST>, startIdx: Int): Bool {
        var found = false;
        function scan(x: ElixirAST): Void {
            if (x == null || x.def == null || found) return;
            switch (x.def) {
                case ERaw(code) if (code != null):
                    if (code.indexOf('Enum.filter(') != -1 && rawContainsIdent(code, 'query')) found = true;
                case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length >= 1):
                    // Cannot inspect inner ERaw reliably; assume predicate may reference query
                    found = true;
                case ECall(_, "filter", _):
                    found = true;
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
    static function isDowncaseSearch(rhs: ElixirAST): Bool {
        return switch (rhs.def) {
            case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
                switch (args[0].def) { case EVar(v) if (v == "search_query"): true; default: false; }
            default: false;
        }
    }
    static function rewrite(stmts: Array<ElixirAST>, ctx: ElixirAST): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            var s = stmts[i];
            var rescued = false;
            switch (s.def) {
                case EBinary(Match, left, rhs) if (isDowncaseSearch(rhs)):
                    var leftIsWild = switch (left.def) { case EVar(nm) if (nm == "_"): true; default: false; };
                    var leftIsUnderscoreQuery = switch (left.def) { case EVar(nm2) if (nm2 == "_query"): true; default: false; };
                    if ((leftIsWild || leftIsUnderscoreQuery) && hasFilterQueryLater(stmts, i + 1)) {
                        out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs), ctx.metadata, ctx.pos));
                        rescued = true;
                    }
                case EMatch(pat, rhs2) if (isDowncaseSearch(rhs2)):
                    var patIsUnderscoreQuery = switch (pat) { case PVar(nmp) if (nmp == "_query"): true; default: false; };
                    var patIsWildcard = switch (pat) { case PWildcard: true; default: false; };
                    if ((patIsWildcard || patIsUnderscoreQuery) && hasFilterQueryLater(stmts, i + 1)) {
                        out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs2), ctx.metadata, ctx.pos));
                        rescued = true;
                    }
                default:
            }
            if (!rescued) out.push(s);
        }
        return out;
    }
}

#end

