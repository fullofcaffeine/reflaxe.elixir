package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropUnusedDowncaseWildcardAssignTransforms
 *
 * WHAT
 * - Drops `_ = String.downcase(search_query)` statements in block-like contexts,
 *   as they are pure and unused when left-hand side is wildcard.
 */
class DropUnusedDowncaseWildcardAssignTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 0): makeASTWithMeta(EBlock(drop(stmts, n)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0): makeASTWithMeta(EDo(drop(stmts2, n)), n.metadata, n.pos);
                default: n;
            }
        });
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
                var isWild = switch (left.def) {
                    case EVar(nm) if (nm == "_"): true;
                    case EUnderscore: true;
                    default: false;
                };
                if (!isWild) return false;
                switch (rhs2.def) {
                    case ERemoteCall({def: EVar(m2)}, "downcase", args2) if (m2 == "String" && args2 != null && args2.length == 1):
                        switch (args2[0].def) { case EVar(v2) if (v2 == "search_query"): true; default: false; }
                    default: false;
                }
            default: false;
        }
    }

    static function drop(stmts: Array<ElixirAST>, ctx: ElixirAST): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        var hasQueryBinder: Bool = false;
        inline function isQueryDowncaseAssign(s: ElixirAST): Bool {
            return switch (s.def) {
                case EBinary(Match, left0, rhs0):
                    var isQuery = switch (left0.def) { case EVar(nm) if (nm == "query"): true; default: false; };
                    if (!isQuery) false else switch (rhs0.def) {
                        case ERemoteCall({def: EVar(m0)}, "downcase", args0) if (m0 == "String" && args0 != null && args0.length == 1):
                            switch (args0[0].def) { case EVar(v0) if (v0 == "search_query"): true; default: false; }
                        default: false;
                    };
                default: false;
            };
        }
        for (i in 0...stmts.length) {
            var s = stmts[i];
            if (isQueryDowncaseAssign(s)) {
                hasQueryBinder = true;
                out.push(s);
            } else if (isWildcardDowncase(s)) {
                if (hasQueryBinder) {
                    // Redundant after a query binder exists; drop
                    #if debug_filter_query_consolidate
                    Sys.println('[DropUnusedDowncaseWildcardAssign] Dropping redundant wildcard downcase');
                    #end
                    continue;
                }
                #if debug_filter_query_consolidate
                Sys.println('[DropUnusedDowncaseWildcardAssign] Promoting wildcard downcase to query binder');
                #end
                // Normalize binder: promote wildcard to a stable local `query` so that
                // later passes relying on `query` can operate deterministically.
                switch (s.def) {
                    case EMatch(_, rhs): out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs), ctx.metadata, ctx.pos));
                    case EBinary(Match, _, rhs2): out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs2), ctx.metadata, ctx.pos));
                    default: // unreachable due to guard
                }
                hasQueryBinder = true;
            } else out.push(s);
        }
        return out;
    }
}

#end
