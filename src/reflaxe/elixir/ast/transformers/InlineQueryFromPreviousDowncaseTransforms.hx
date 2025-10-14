package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineQueryFromPreviousDowncaseTransforms
 *
 * WHAT
 * - When a block contains `_ = String.downcase(x)` immediately before an
 *   `Enum.filter(..., fn ... -> ... end)` whose predicate body references `query`
 *   and no prior binding for `query` exists, replace occurrences of `query` in
 *   the predicate body with the RHS expression `String.downcase(x)`.
 *
 * WHY
 * - Avoid undefined-variable errors without introducing new binders. Keeps the
 *   predicate self-contained and shape-based.
 *
 * HOW
 * - Scan adjacent statement pairs for `_ = String.downcase(_)` followed by an
 *   Enum.filter(..., fn ...) where the predicate body references `query` and no
 *   prior `query` binding exists. Inline the downcase expression into those
 *   references within the predicate body.
 *
 * EXAMPLES
 * Elixir (before):
 *   _ = String.downcase(term)
 *   Enum.filter(list, fn -> String.contains?(query, term) end)
 * Elixir (after):
 *   _ = String.downcase(term)
 *   Enum.filter(list, fn -> String.contains?(String.downcase(term), term) end)
 */
class InlineQueryFromPreviousDowncaseTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 1): makeASTWithMeta(EBlock(rewrite(stmts, n)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 1): makeASTWithMeta(EDo(rewrite(stmts2, n)), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function rewrite(stmts:Array<ElixirAST>, ctx: ElixirAST): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        function hasDefinedQuery(before:Int): Bool {
            for (k in 0...before) switch (stmts[k].def) {
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): return true; default: }
                case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): return true; default: }
                default:
            }
            return false;
        }
        function inlineQuery(body: ElixirAST, rhs: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) {
                    case EVar(nm) if (nm == "query"): rhs;
                    default: x;
                };
            });
        }
        var i = 0;
        while (i < stmts.length) {
            var s = stmts[i];
            if (i + 1 < stmts.length) {
                var next = stmts[i + 1];
                var rhs: Null<ElixirAST> = null;
                switch (s.def) {
                    case EMatch(PWildcard, r):
                        switch (r.def) {
                            case ERemoteCall({def: EVar(m)}, "downcase", _ ) if (m == "String"): rhs = r;
                            default:
                        }
                    default:
                }
                var canInline = (rhs != null) && !hasDefinedQuery(i);
                if (canInline) {
                    switch (next.def) {
                        case ERemoteCall(mod, "filter", args) if (args.length == 2):
                            switch (args[1].def) {
                                case EFn(clauses) if (clauses.length == 1):
                                    var cl = clauses[0];
                                    var newBody = inlineQuery(cl.body, rhs);
                                    var newFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]));
                                    var newDef = ERemoteCall(mod, "filter", [args[0], newFn]);
                                    out.push(s);
                                    out.push(makeASTWithMeta(newDef, next.metadata, next.pos));
                                    i += 2;
                                    continue;
                                default:
                            }
                        case ECall(target, "filter", args2) if (args2.length == 2):
                            switch (args2[1].def) {
                                case EFn(clauses2) if (clauses2.length == 1):
                                    var cl2 = clauses2[0];
                                    var nb = inlineQuery(cl2.body, rhs);
                                    var newFn2 = makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: nb }]));
                                    var newDef2 = ECall(target, "filter", [args2[0], newFn2]);
                                    out.push(s);
                                    out.push(makeASTWithMeta(newDef2, next.metadata, next.pos));
                                    i += 2;
                                    continue;
                                default:
                            }
                        case EMatch(lhs, rhs2):
                            switch (rhs2.def) {
                                case ERemoteCall(mod2, "filter", a3) if (a3.length == 2):
                                    switch (a3[1].def) {
                                        case EFn(clauses3) if (clauses3.length == 1):
                                            var cl3 = clauses3[0];
                                            var nb3 = inlineQuery(cl3.body, rhs);
                                            var newFn3 = makeAST(EFn([{ args: cl3.args, guard: cl3.guard, body: nb3 }]));
                                            var newRhs = makeASTWithMeta(ERemoteCall(mod2, "filter", [a3[0], newFn3]), rhs2.metadata, rhs2.pos);
                                            out.push(s);
                                            out.push(makeASTWithMeta(EMatch(lhs, newRhs), next.metadata, next.pos));
                                            i += 2;
                                            continue;
                                        default:
                                    }
                                case ECall(target2, "filter", a4) if (a4.length == 2):
                                    switch (a4[1].def) {
                                        case EFn(clauses4) if (clauses4.length == 1):
                                            var cl4 = clauses4[0];
                                            var nb4 = inlineQuery(cl4.body, rhs);
                                            var newFn4 = makeAST(EFn([{ args: cl4.args, guard: cl4.guard, body: nb4 }]));
                                            var newRhs2 = makeASTWithMeta(ECall(target2, "filter", [a4[0], newFn4]), rhs2.metadata, rhs2.pos);
                                            out.push(s);
                                            out.push(makeASTWithMeta(EMatch(lhs, newRhs2), next.metadata, next.pos));
                                            i += 2;
                                            continue;
                                        default:
                                    }
                                default:
                            }
                        default:
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
