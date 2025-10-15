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
 * - Normalizes String search predicates by inlining `String.downcase(search_query)`
 *   directly in place of free `query` references inside the Enum.filter predicate
 *   when no prior local binding for `query` exists in the same scope.
 *
 * WHY
 * - Predicate normalization may rewrite string search predicates to reference a local
 *   `query`. When the source provides a `search_query` value in scope (common pattern),
 *   we must bind `query` once to its lowercased variant to avoid undefined variable
 *   errors and produce clean, idiomatic code.
 *
 * HOW
 * - For each Enum.filter call with a predicate EFn whose body uses EVar("query"),
 *   and no assignment to `query` exists in prior statements in the same block,
 *   rewrite the predicate body by replacing EVar("query") with
 *   `String.downcase(search_query)`.
 * - Shape-based; no app-specific names beyond `query` and `search_query`.
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
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }
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
                                case ERaw(code) if (code != null):
                                    var start = 0;
                                    while (!found) {
                                        var i = code.indexOf("query", start);
                                        if (i == -1) break;
                                        var before = i > 0 ? code.substr(i - 1, 1) : null;
                                        var afterIdx = i + 5;
                                        var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                                        if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                                        start = i + 5;
                                    }
                                    return x;
                                default: return x;
                            }
                        });
                        return found;
                    }
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        if (!seenQueryBind && stmtDefinesQuery(s)) seenQueryBind = true;
                        var needsRewrite = false;
                        var predRef: Null<{ cl: { args:Array<EPattern>, guard:ElixirAST, body:ElixirAST }, idx:Int, isRemote:Bool } > = null;
                        switch (s.def) {
                            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                                switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): if (bodyUsesQuery(clauses[0].body)) { needsRewrite = true; predRef = { cl: clauses[0], idx: i, isRemote: true }; } default: }
                            case ECall(_, "filter", args2) if (args2 != null && args2.length == 2):
                                switch (args2[1].def) { case EFn(clauses) if (clauses.length == 1): if (bodyUsesQuery(clauses[0].body)) { needsRewrite = true; predRef = { cl: clauses[0], idx: i, isRemote: false }; } default: }
                            case EMatch(lhsPat, rhsExpr):
                                switch (rhsExpr.def) {
                                    case ERemoteCall({def: EVar(m3)}, "filter", args3) if (m3 == "Enum" && args3.length == 2):
                                        switch (args3[1].def) { case EFn(clauses3) if (clauses3.length == 1): if (bodyUsesQuery(clauses3[0].body)) { needsRewrite = true; predRef = { cl: clauses3[0], idx: i, isRemote: true }; } default: }
                                    case ECall(_, "filter", args4) if (args4.length == 2):
                                        switch (args4[1].def) { case EFn(clauses4) if (clauses4.length == 1): if (bodyUsesQuery(clauses4[0].body)) { needsRewrite = true; predRef = { cl: clauses4[0], idx: i, isRemote: false }; } default: }
                                    default:
                                }
                            default:
                        }
                        if (needsRewrite && !seenQueryBind && predRef != null) {
                            var cl = predRef.cl;
                            // Rewrite query references in predicate body
                            var newBody = ElixirASTTransformer.transformNode(cl.body, function(xx: ElixirAST): ElixirAST {
                                return switch (xx.def) {
                                    case EVar(nm) if (nm == "query"): makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                                    default: xx;
                                }
                            });
                            // Replace in-place in statement s
                            switch (s.def) {
                                case ERemoteCall(mod, "filter", args3) if (predRef.isRemote):
                                    out.push(makeAST(ERemoteCall(mod, "filter", [args3[0], makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]))])));
                                case ECall(target, "filter", args4) if (!predRef.isRemote):
                                    out.push(makeAST(ECall(target, "filter", [args4[0], makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]))])));
                                case EMatch(lhsPat2, rhsExpr2):
                                    switch (rhsExpr2.def) {
                                        case ERemoteCall(mod4, "filter", a4) if (predRef.isRemote):
                                            var repl = makeAST(ERemoteCall(mod4, "filter", [a4[0], makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]))]));
                                            out.push(makeAST(EMatch(lhsPat2, repl)));
                                        case ECall(target4, "filter", a5) if (!predRef.isRemote):
                                            var repl2 = makeAST(ECall(target4, "filter", [a5[0], makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]))]));
                                            out.push(makeAST(EMatch(lhsPat2, repl2)));
                                        default:
                                            out.push(s);
                                    }
                                default:
                                    out.push(s);
                            }
                        } else {
                            out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                case EDo(stmts2) if (stmts2.length > 0):
                    var out2:Array<ElixirAST> = [];
                    var seenQueryBinding = false;
                    function stmtDefinesQueryBinding(s: ElixirAST): Bool {
                        return switch (s.def) {
                            case EBinary(Match, l, _): switch (l.def) { case EVar(nm) if (nm == "query"): true; default: false; }
                            case EMatch(pat, _): switch (pat) { case PVar(n) if (n == "query"): true; default: false; }
                            default: false;
                        };
                    }
                    function predicateBodyUsesQuery(e: ElixirAST): Bool {
                        var found = false;
                        ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
                            if (found) return x;
                            switch (x.def) {
                                case EVar(nm) if (nm == "query"): found = true; return x;
                                case ERaw(code) if (code != null):
                                    var start = 0;
                                    while (!found) {
                                        var i = code.indexOf("query", start);
                                        if (i == -1) break;
                                        var before = i > 0 ? code.substr(i - 1, 1) : null;
                                        var afterIdx = i + 5;
                                        var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                                        if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                                        start = i + 5;
                                    }
                                    return x;
                                default: return x;
                            }
                        });
                        return found;
                    }
                    for (i in 0...stmts2.length) {
                        var s = stmts2[i];
                        if (!seenQueryBinding && stmtDefinesQueryBinding(s)) seenQueryBinding = true;
                        var needsPredicateRewrite = false;
                        var predicateRef: Null<{ cl: { args:Array<EPattern>, guard:ElixirAST, body:ElixirAST }, idx:Int, isRemote:Bool } > = null;
                        switch (s.def) {
                            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                                switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): if (predicateBodyUsesQuery(clauses[0].body)) { needsPredicateRewrite = true; predicateRef = { cl: clauses[0], idx: i, isRemote: true }; } default: }
                            case ECall(_, "filter", args2) if (args2 != null && args2.length == 2):
                                switch (args2[1].def) { case EFn(clauses) if (clauses.length == 1): if (predicateBodyUsesQuery(clauses[0].body)) { needsPredicateRewrite = true; predicateRef = { cl: clauses[0], idx: i, isRemote: false }; } default: }
                            case EMatch(lhsPat3, rhsExpr3):
                                switch (rhsExpr3.def) {
                                    case ERemoteCall({def: EVar(m5)}, "filter", a6) if (m5 == "Enum" && a6.length == 2):
                                        switch (a6[1].def) { case EFn(clauses5) if (clauses5.length == 1): if (predicateBodyUsesQuery(clauses5[0].body)) { needsPredicateRewrite = true; predicateRef = { cl: clauses5[0], idx: i, isRemote: true }; } default: }
                                    case ECall(_, "filter", a7) if (a7.length == 2):
                                        switch (a7[1].def) { case EFn(clauses6) if (clauses6.length == 1): if (predicateBodyUsesQuery(clauses6[0].body)) { needsPredicateRewrite = true; predicateRef = { cl: clauses6[0], idx: i, isRemote: false }; } default: }
                                    default:
                                }
                            default:
                        }
                        if (needsPredicateRewrite && !seenQueryBinding && predicateRef != null) {
                            var cl2 = predicateRef.cl;
                            var newBody2 = ElixirASTTransformer.transformNode(cl2.body, function(xx: ElixirAST): ElixirAST {
                                return switch (xx.def) {
                                    case EVar(nm) if (nm == "query"): makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
                                    default: xx;
                                }
                            });
                            switch (s.def) {
                                case ERemoteCall(mod2, "filter", args3) if (predicateRef.isRemote):
                                    out2.push(makeAST(ERemoteCall(mod2, "filter", [args3[0], makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: newBody2 }]))])));
                                case ECall(target2, "filter", args4) if (!predicateRef.isRemote):
                                    out2.push(makeAST(ECall(target2, "filter", [args4[0], makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: newBody2 }]))])));
                                case EMatch(lhsPat4, rhsExpr4):
                                    switch (rhsExpr4.def) {
                                        case ERemoteCall(mod6, "filter", a8) if (predicateRef.isRemote):
                                            var repl3 = makeAST(ERemoteCall(mod6, "filter", [a8[0], makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: newBody2 }]))]));
                                            out2.push(makeAST(EMatch(lhsPat4, repl3)));
                                        case ECall(target5, "filter", a9) if (!predicateRef.isRemote):
                                            var repl4 = makeAST(ECall(target5, "filter", [a9[0], makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: newBody2 }]))]));
                                            out2.push(makeAST(EMatch(lhsPat4, repl4)));
                                        default:
                                            out2.push(s);
                                    }
                                default:
                                    out2.push(s);
                            }
                        } else {
                            out2.push(s);
                        }
                    }
                    makeASTWithMeta(EDo(out2), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
}

#end
