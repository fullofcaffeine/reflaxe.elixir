package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterQueryBinderTransforms
 *
 * WHAT
 * - Synthesizes a local `query = String.downcase(search_query)` binding immediately
 *   before Enum.filter(list, predicate) when the predicate references `query` and
 *   there is no prior local binding for `query` in the same block scope.
 *
 * WHY
 * - Predicate normalization may rewrite string search predicates to reference a local
 *   `query`. When the source provides a `search_query` value in scope (common pattern),
 *   we must bind `query` once to its lowercased variant to avoid undefined variable
 *   errors and produce clean, idiomatic code.
 *
 * HOW
 * - Operates on EBlock([...]) only. For each statement s[i] that is an Enum.filter call
 *   with a predicate EFn whose body uses EVar("query"), and no assignment to `query`
 *   exists in any preceding statements in the same block, insert before s[i] a new
 *   statement: `query = String.downcase(search_query)`.
 * - The synthesis is shape-based; no app-specific names beyond `query` and
 *   `search_query` (expected variable sources).
 *
 * EXAMPLES
 * Before:
 *   Enum.filter(todos, fn t -> String.contains?(t.title, query) end)
 * After:
 *   query = String.downcase(search_query)
 *   Enum.filter(todos, fn t -> String.contains?(t.title, query) end)
 */
class FilterQueryBinderTransforms {
    public static function synthesizeQueryBindingPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts) if (stmts.length > 0):
                    var out:Array<ElixirAST> = [];
                    var seenQueryBind = false;
                    function stmtDefinesQuery(s: ElixirAST): Bool {
                        return switch (s.def) {
                            case EBinary(Match, l, _): switch (l.def) { case EVar(nm) if (nm == "query"): true; default: false; }
                            case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): true; default: false; }
                            default: false;
                        };
                    }
                    function bodyUsesQuery(e: ElixirAST): Bool {
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
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        if (!seenQueryBind && stmtDefinesQuery(s)) seenQueryBind = true;
                        var needsSynth = false;
                        switch (s.def) {
                            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                                switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): if (bodyUsesQuery(clauses[0].body)) needsSynth = true; default: }
                            case ECall(_, "filter", args2) if (args2 != null && args2.length == 2):
                                switch (args2[1].def) { case EFn(clauses2) if (clauses2.length == 1): if (bodyUsesQuery(clauses2[0].body)) needsSynth = true; default: }
                            default:
                        }
                        if (needsSynth && !seenQueryBind) {
                            var down = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            out.push(makeAST(EBinary(Match, makeAST(EVar("query")), down)));
                            seenQueryBind = true;
                        }
                        out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                case EDo(stmts2) if (stmts2.length > 0):
                    var out2:Array<ElixirAST> = [];
                    var seenQueryBind2 = false;
                    function stmtDefinesQuery2(s: ElixirAST): Bool {
                        return switch (s.def) {
                            case EBinary(Match, l, _): switch (l.def) { case EVar(nm) if (nm == "query"): true; default: false; }
                            case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): true; default: false; }
                            default: false;
                        };
                    }
                    function bodyUsesQuery2(e: ElixirAST): Bool {
                        var found = false;
                        ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                            if (found) return x; switch (x.def) {
                                case EVar(nm) if (nm == "query"): found = true; return x;
                                default: return x;
                            }
                        });
                        return found;
                    }
                    for (i in 0...stmts2.length) {
                        var s = stmts2[i];
                        if (!seenQueryBind2 && stmtDefinesQuery2(s)) seenQueryBind2 = true;
                        var needsSynth2 = false;
                        switch (s.def) {
                            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                                switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): if (bodyUsesQuery2(clauses[0].body)) needsSynth2 = true; default: }
                            case ECall(_, "filter", args2) if (args2 != null && args2.length == 2):
                                switch (args2[1].def) { case EFn(clauses2) if (clauses2.length == 1): if (bodyUsesQuery2(clauses2[0].body)) needsSynth2 = true; default: }
                            default:
                        }
                        if (needsSynth2 && !seenQueryBind2) {
                            var down2 = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                            out2.push(makeAST(EBinary(Match, makeAST(EVar("query")), down2)));
                            seenQueryBind2 = true;
                        }
                        out2.push(s);
                    }
                    makeASTWithMeta(EDo(out2), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
}

#end
