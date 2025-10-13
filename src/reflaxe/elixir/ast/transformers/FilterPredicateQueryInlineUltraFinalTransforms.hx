package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterPredicateQueryInlineUltraFinalTransforms
 *
 * WHAT
 * - Ultra-final safeguard: when an Enum.filter predicate references `query` and
 *   there is no prior local binding for `query` in the surrounding block, but the
 *   block does reference `search_query`, inline `query` in the predicate body as
 *   `String.downcase(search_query)`.
 *
 * WHY
 * - Prevent undefined-variable errors in string search filters when the binder did
 *   not survive earlier passes but `search_query` is present in scope.
 */
class FilterPredicateQueryInlineUltraFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts) if (stmts.length > 0): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
                case EDo(stmts2) if (stmts2.length > 0): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        function hasDefinedQuery(before:Int): Bool {
            for (k in 0...before) switch (stmts[k].def) {
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): return true; default: }
                case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): return true; default: }
                default:
            }
            return false;
        }
        function blockHasSearchQuery(): Bool {
            var found = false;
            for (s in stmts) {
                ElixirASTTransformer.transformNode(s, function(x: ElixirAST): ElixirAST {
                    if (found) return x;
                    switch (x.def) {
                        case EVar(nm) if (nm == "search_query"): found = true; return x;
                        default: return x;
                    }
                });
                if (found) break;
            }
            return found;
        }
        inline function inlineQuery(body: ElixirAST): ElixirAST {
            var repl = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
            return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) {
                    case EVar(nm) if (nm == "query"): repl;
                    case ERaw(code) if (code != null):
                        // Token-boundary replacement of 'query' → 'String.downcase(search_query)'
                        var out = new StringBuf();
                        var i = 0;
                        while (i < code.length) {
                            var idx = code.indexOf("query", i);
                            if (idx == -1) { out.add(code.substr(i)); break; }
                            // Check token boundaries
                            var before = idx > 0 ? code.substr(idx - 1, 1) : null;
                            var afterIdx = idx + 5;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            var isIdent = function(c:String):Bool {
                                if (c == null || c.length == 0) return false;
                                var ch = c.charCodeAt(0);
                                return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
                            };
                            if (!isIdent(before) && !isIdent(after)) {
                                out.add(code.substr(i, idx - i));
                                out.add("String.downcase(search_query)");
                                i = afterIdx;
                            } else {
                                out.add(code.substr(i, (idx - i) + 5));
                                i = idx + 5;
                            }
                        }
                        makeASTWithMeta(ERaw(out.toString()), x.metadata, x.pos);
                    default: x;
                };
            });
        }
        var canInline = blockHasSearchQuery();
        for (i in 0...stmts.length) {
            var s = stmts[i];
            if (canInline && !hasDefinedQuery(i)) {
                switch (s.def) {
                    case ERemoteCall(mod, "filter", args) if (args.length == 2):
                        switch (args[1].def) {
                            case EFn(clauses) if (clauses.length == 1):
                                var cl = clauses[0];
                                var usesQuery = false;
                                ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                                    if (usesQuery) return x; switch (x.def) { case EVar(nm) if (nm == "query"): usesQuery = true; return x; default: return x; }
                                });
                                if (usesQuery) {
                                    var nb = inlineQuery(cl.body);
                                    var newFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: nb }]));
                                    out.push(makeASTWithMeta(ERemoteCall(mod, "filter", [args[0], newFn]), s.metadata, s.pos));
                                    continue;
                                }
                            default:
                        }
                    case ECall(target, "filter", args2) if (args2.length == 2):
                        switch (args2[1].def) {
                            case EFn(clauses2) if (clauses2.length == 1):
                                var cl2 = clauses2[0];
                                var usesQ = false;
                                ElixirASTTransformer.transformNode(cl2.body, function(x2: ElixirAST): ElixirAST {
                                    if (usesQ) return x2; switch (x2.def) { case EVar(nm2) if (nm2 == "query"): usesQ = true; return x2; default: return x2; }
                                });
                                if (usesQ) {
                                    var nb2 = inlineQuery(cl2.body);
                                    var newFn2 = makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: nb2 }]));
                                    out.push(makeASTWithMeta(ECall(target, "filter", [args2[0], newFn2]), s.metadata, s.pos));
                                    continue;
                                }
                            default:
                        }
                    case EMatch(lhs, rhs):
                        switch (rhs.def) {
                            case ERemoteCall(mod2, "filter", a3) if (a3.length == 2):
                                switch (a3[1].def) {
                                    case EFn(clauses3) if (clauses3.length == 1):
                                        var cl3 = clauses3[0]; var uq = false;
                                        ElixirASTTransformer.transformNode(cl3.body, function(xx: ElixirAST): ElixirAST { if (uq) return xx; switch (xx.def) { case EVar(nmm) if (nmm == "query"): uq = true; return xx; default: return xx; } });
                                        if (uq) {
                                            var nb3 = inlineQuery(cl3.body);
                                            var newFn3 = makeAST(EFn([{ args: cl3.args, guard: cl3.guard, body: nb3 }]));
                                            out.push(makeASTWithMeta(EMatch(lhs, makeAST(ERemoteCall(mod2, "filter", [a3[0], newFn3]))), s.metadata, s.pos));
                                            continue;
                                        }
                                    default:
                                }
                            case ECall(target2, "filter", a4) if (a4.length == 2):
                                switch (a4[1].def) {
                                    case EFn(clauses4) if (clauses4.length == 1):
                                        var cl4 = clauses4[0]; var uq2 = false;
                                        ElixirASTTransformer.transformNode(cl4.body, function(yy: ElixirAST): ElixirAST { if (uq2) return yy; switch (yy.def) { case EVar(nn) if (nn == "query"): uq2 = true; return yy; default: return yy; } });
                                        if (uq2) {
                                            var nb4 = inlineQuery(cl4.body);
                                            var newFn4 = makeAST(EFn([{ args: cl4.args, guard: cl4.guard, body: nb4 }]));
                                            out.push(makeASTWithMeta(EMatch(lhs, makeAST(ECall(target2, "filter", [a4[0], newFn4]))), s.metadata, s.pos));
                                            continue;
                                        }
                                    default:
                                }
                            default:
                        }
                    default:
                }
            }
            out.push(s);
        }
        return out;
    }
}

#end
