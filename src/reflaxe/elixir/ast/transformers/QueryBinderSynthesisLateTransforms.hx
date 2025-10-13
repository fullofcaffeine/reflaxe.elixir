package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * QueryBinderSynthesisLateTransforms
 *
 * WHAT
 * - Ultra-late pass that inserts `query = String.downcase(search_query)` immediately
 *   before Enum.filter calls whose predicate EFn body references `query` and where
 *   no prior local binding for `query` exists in the block.
 *
 * WHY
 * - Prevent undefined-variable errors in string search filters when earlier passes
 *   normalize to a `query` variable but the binder was discarded/missed.
 *
 * HOW
 * - For each EBlock/EDo statement list:
 *   - Track whether `query` has been defined so far in the list.
 *   - For any statement that calls Enum.filter(list, fn ... -> ... end) and the EFn
 *     body contains EVar("query"), if `query` has not yet been defined, insert a
 *     binding `query = String.downcase(search_query)` right before the statement.
 */
class QueryBinderSynthesisLateTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 0):
                    makeASTWithMeta(EBlock(synthesize(stmts, n)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0):
                    makeASTWithMeta(EDo(synthesize(stmts2, n)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function synthesize(stmts:Array<ElixirAST>, ctxNode: ElixirAST): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var queryDefined = false;
        inline function definesQuery(s: ElixirAST): Bool {
            return switch (s.def) {
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): true; default: false; }
                case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): true; default: false; }
                default: false;
            };
        }
        inline function bodyUsesQuery(e: ElixirAST): Bool {
            var found = false;
            ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                if (found) return x;
                switch (x.def) {
                    case EVar(nm) if (nm == "query"): found = true; return x;
                    default: return x;
                }
            });
            return found;
        }
        function nearestDowncase(before:Int): Null<ElixirAST> {
            for (k in (before - 1) ... -1) {
                if (k < 0) break;
                switch (stmts[k].def) {
                    case EMatch(_, rhs):
                        switch (rhs.def) {
                            case ERemoteCall({def: EVar(m)}, "downcase", _) if (m == "String"): return rhs;
                            default:
                        }
                    case EBinary(Match, _, rhs2):
                        switch (rhs2.def) {
                            case ERemoteCall({def: EVar(m2)}, "downcase", _) if (m2 == "String"): return rhs2;
                            default:
                        }
                    default:
                }
            }
            return null;
        }

        for (i in 0...stmts.length) {
            var s = stmts[i];
            if (!queryDefined && definesQuery(s)) queryDefined = true;
            var needsSynth = false;
            switch (s.def) {
                case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                    switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): if (bodyUsesQuery(clauses[0].body)) needsSynth = true; default: }
                case ECall(_, "filter", args2) if (args2 != null && args2.length == 2):
                    switch (args2[1].def) { case EFn(clauses2) if (clauses2.length == 1): if (bodyUsesQuery(clauses2[0].body)) needsSynth = true; default: }
                case EMatch(_, rhs):
                    switch (rhs.def) {
                        case ERemoteCall({def: EVar(m3)}, "filter", a3) if (m3 == "Enum" && a3 != null && a3.length == 2):
                            switch (a3[1].def) { case EFn(clauses3) if (clauses3.length == 1): if (bodyUsesQuery(clauses3[0].body)) needsSynth = true; default: }
                        case ECall(_, "filter", a4) if (a4 != null && a4.length == 2):
                            switch (a4[1].def) { case EFn(clauses4) if (clauses4.length == 1): if (bodyUsesQuery(clauses4[0].body)) needsSynth = true; default: }
                        default:
                    }
                default:
            }
            if (needsSynth && !queryDefined) {
                var rhs = nearestDowncase(i);
                if (rhs != null) {
                    out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("query")), rhs), ctxNode.metadata, ctxNode.pos));
                    queryDefined = true;
                }
            }
            out.push(s);
        }
        return out;
    }
}

#end
