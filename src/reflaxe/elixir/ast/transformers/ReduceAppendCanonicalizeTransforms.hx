package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * ReduceAppendCanonicalizeTransforms
 *
 * WHAT
 * - Canonicalizes append patterns inside Enum.reduce/3 reducers to use the accumulator name directly
 *   and the binder for the element, removing fragile local aliasing.
 *
 * WHY
 * - Some pipelines produce bodies like:
 *     todo = entry
 *     todo_items = Enum.concat(todo_items, [render_todo_item(todo, assigns.editing_todo)])
 *     acc
 *   which triggers undefined variable errors (RHS uses `todo_items` before bind) and non-idiomatic forms.
 *   This pass rewrites such shapes to:
 *     acc = Enum.concat(acc, [render_todo_item(entry, assigns.editing_todo)])
 *     acc
 *
 * HOW
 * - Match ERemoteCall(_, "reduce", [list, init, fn]) with single-clause EFn having two args `(binder, acc)`.
 * - Inside the reducer body:
 *   1) Remember a local alias of the binder if present: `local = binder`.
 *   2) Rewrite any `alias = Enum.concat(alias, [expr])` to `acc = Enum.concat(acc, [expr'])` where expr' replaces
 *      occurrences of the local alias with the binder.
 *   3) Keep all other statements; ensure body still returns acc.
 */
class ReduceAppendCanonicalizeTransforms {
    static function containsVar(ast: ElixirAST, name: String): Bool {
        var found = false;
        ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            switch (n.def) { case EVar(v) if (v == name): found = true; default: }
            return n;
        });
        return found;
    }
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(modRef, "reduce", args) if (args.length == 3):
                    var listExpr = args[0];
                    var init = args[1];
                    var fnNode = args[2];
                    switch (fnNode.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var cl = clauses[0];
                            if (cl.args.length < 2) return n;
                            var binderName:Null<String> = switch (cl.args[0]) { case PVar(b): b; default: null; };
                            var accName:Null<String> = switch (cl.args[1]) { case PVar(a): a; default: null; };
                            if (binderName == null || accName == null) return n;
                            Sys.println('[ReduceAppendCanonicalize] reducer binder=' + binderName + ', acc=' + accName);

                            var bodyStmts:Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                            var elementAlias:Null<String> = null;
                            // First pass: detect element alias `local = binder`
                            for (s in bodyStmts) switch (s.def) {
                                case EBinary(Match, left, right):
                                    var lhs:Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                                    var rhsIsBinder = switch (right.def) { case EVar(n2) if (n2 == binderName): true; default: false; };
                                    if (lhs != null && rhsIsBinder) elementAlias = lhs;
                                case EMatch(patX, rhsX):
                                    var lhs2:Null<String> = switch (patX) { case PVar(n3): n3; default: null; };
                                    var rhsIsBinder2 = switch (rhsX.def) { case EVar(n4) if (n4 == binderName): true; default: false; };
                                    if (lhs2 != null && rhsIsBinder2) elementAlias = lhs2;
                                default:
                            }
                            if (elementAlias != null) Sys.println('[ReduceAppendCanonicalize] found alias of binder: ' + elementAlias + ' = ' + binderName);
                            // Second pass: rewrite alias concat to acc concat and substitute alias->binder in RHS list expr
                            var newBody:Array<ElixirAST> = [];
                            var didRewrite = false;
                            for (stmt in bodyStmts) {
                                #if debug_presence
                                Sys.println('[ReduceAppendCanonicalize] stmt=' + ElixirASTPrinter.print(stmt, 0));
                                #end
                                var localRewrote = false;
                                var rewritten = ElixirASTTransformer.transformNode(stmt, function(node: ElixirAST): ElixirAST {
                                    return switch (node.def) {
                                        case EBinary(Match, left, rhs):
                                            Sys.println('[ReduceAppendCanonicalize] HIT EBinary(Match) ' + ElixirASTPrinter.print(node, 0));
                                            var lhs:Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                                            if (lhs != null && containsVar(rhs, lhs)) {
                                                localRewrote = true;
                                                var rhs2 = ElixirASTTransformer.transformNode(rhs, function(t: ElixirAST): ElixirAST {
                                                    return switch (t.def) {
                                                        case EVar(v) if (v == lhs): makeASTWithMeta(EVar(accName), t.metadata, t.pos);
                                                        case EVar(v2) if (elementAlias != null && v2 == elementAlias): makeASTWithMeta(EVar(binderName), t.metadata, t.pos);
                                                        default: t;
                                                    }
                                                });
                                                makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), rhs2), node.metadata, node.pos);
                                            } else switch (rhs.def) {
                                                case ERemoteCall(_, "concat", cargs) if (lhs != null && cargs.length == 2):
                                                    var arg0IsLhs = switch (cargs[0].def) { case EVar(n2): (n2 == lhs); default: false; };
                                                    if (arg0IsLhs) {
                                                        localRewrote = true;
                                                        var rhsList2 = (elementAlias == null) ? cargs[1] : ElixirASTTransformer.transformNode(cargs[1], function(x: ElixirAST): ElixirAST {
                                                            return switch (x.def) {
                                                                case EVar(v) if (v == elementAlias): makeASTWithMeta(EVar(binderName), x.metadata, x.pos);
                                                                default: x;
                                                            }
                                                        });
                                                        makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), rhsList2]))), node.metadata, node.pos);
                                                    } else node;
                                                case EBinary(Concat, lcat, rcat):
                                                    var lhsIsCat = switch (lcat.def) { case EVar(nlc) if (lhs != null && nlc == lhs): true; default: false; };
                                                    if (lhsIsCat) {
                                                        localRewrote = true;
                                                        var list2 = (elementAlias == null) ? rcat : ElixirASTTransformer.transformNode(rcat, function(x2: ElixirAST): ElixirAST {
                                                            return switch (x2.def) {
                                                                case EVar(vv) if (vv == elementAlias): makeASTWithMeta(EVar(binderName), x2.metadata, x2.pos);
                                                                default: x2;
                                                            }
                                                        });
                                                        makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), list2]))), node.metadata, node.pos);
                                                    } else node;
                                                case ECall(_, "concat", cargsC) if (lhs != null && cargsC.length == 2):
                                                    var isSelfC = switch (cargsC[0].def) { case EVar(nc) if (nc == lhs): true; default: false; };
                                                    if (isSelfC) {
                                                        localRewrote = true;
                                                        var rhsL2 = (elementAlias == null) ? cargsC[1] : ElixirASTTransformer.transformNode(cargsC[1], function(z: ElixirAST): ElixirAST {
                                                            return switch (z.def) {
                                                                case EVar(vz) if (vz == elementAlias): makeASTWithMeta(EVar(binderName), z.metadata, z.pos);
                                                                default: z;
                                                            }
                                                        });
                                                        makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), rhsL2]))), node.metadata, node.pos);
                                                    } else node;
                                                default:
                                                    node;
                                            }
                                        case EMatch(pat, rhs2):
                                            var lhs2:Null<String> = switch (pat) { case PVar(n): n; default: null; };
                                            if (lhs2 != null && containsVar(rhs2, lhs2)) {
                                                localRewrote = true;
                                                var rhs2b = ElixirASTTransformer.transformNode(rhs2, function(t2: ElixirAST): ElixirAST {
                                                    return switch (t2.def) {
                                                        case EVar(vp) if (vp == lhs2): makeASTWithMeta(EVar(accName), t2.metadata, t2.pos);
                                                        case EVar(vp2) if (elementAlias != null && vp2 == elementAlias): makeASTWithMeta(EVar(binderName), t2.metadata, t2.pos);
                                                        default: t2;
                                                    }
                                                });
                                                makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), rhs2b), node.metadata, node.pos);
                                            } else switch (rhs2.def) {
                                                case ERemoteCall(_, "concat", cargs2) if (lhs2 != null && cargs2.length == 2):
                                                    var arg0IsLhs2 = switch (cargs2[0].def) { case EVar(n3): (n3 == lhs2); default: false; };
                                                    if (arg0IsLhs2) {
                                                        localRewrote = true;
                                                        var rhsListM2 = (elementAlias == null) ? cargs2[1] : ElixirASTTransformer.transformNode(cargs2[1], function(y: ElixirAST): ElixirAST {
                                                            return switch (y.def) {
                                                                case EVar(v2) if (v2 == elementAlias): makeASTWithMeta(EVar(binderName), y.metadata, y.pos);
                                                                default: y;
                                                            }
                                                        });
                                                        makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), rhsListM2]))), node.metadata, node.pos);
                                                    } else node;
                                                default:
                                                    node;
                                            }
                                        default:
                                            node;
                                    }
                                });
                                if (localRewrote) didRewrite = true;
                                newBody.push(rewritten);
                            }
                            // Fallback: If no specific statement was rewritten but there is any
                            // Enum.concat(_, list) call in the body, rebuild body as
                            // acc = Enum.concat(acc, list') ; acc
                            var usedSpecificRewrite = didRewrite;
                            if (!usedSpecificRewrite) {
                                Sys.println('[ReduceAppendCanonicalize] entering fallback with alias=' + elementAlias);
                                var foundList:Null<ElixirAST> = null;
                                var foundExpr:Null<ElixirAST> = null;
                                for (stmt2 in bodyStmts) {
                                    ASTUtils.walk(stmt2, function(n2: ElixirAST) {
                                        switch (n2.def) {
                                            case ERemoteCall(modX, "concat", argsX) if (argsX.length == 2):
                                                // Capture list arg
                                                foundList = argsX[1];
                                                Sys.println('[ReduceAppendCanonicalize] walk found ERemoteCall concat: ' + ElixirASTPrinter.print(n2, 0));
                                            case ECall(_, "concat", argsCX) if (argsCX.length == 2):
                                                foundList = argsCX[1];
                                                Sys.println('[ReduceAppendCanonicalize] walk found ECall concat: ' + ElixirASTPrinter.print(n2, 0));
                                            case EList(itemsX) if (itemsX.length == 1):
                                                // Capture singleton list element if present
                                                if (foundExpr == null) foundExpr = itemsX[0];
                                            default:
                                        }
                                    });
                                    if (foundList != null) break;
                                }
                                Sys.println('[ReduceAppendCanonicalize] fallback foundList=' + (foundList == null ? 'null' : ElixirASTPrinter.print(foundList, 0)) + ', foundExpr=' + (foundExpr == null ? 'null' : ElixirASTPrinter.print(foundExpr, 0)));
                                // Guard: only rebuild if body currently returns acc
                                var returnsAcc = switch (bodyStmts.length > 0 ? bodyStmts[bodyStmts.length - 1].def : ENil) { case EVar(v) if (v == accName): true; default: false; };
                                if ((foundList != null || foundExpr != null) && returnsAcc) {
                                    var listNode:ElixirAST = (foundList != null) ? foundList : makeAST(EList([foundExpr]));
                                    var listPrime = (elementAlias == null) ? listNode : ElixirASTTransformer.transformNode(listNode, function(w: ElixirAST): ElixirAST {
                                        return switch (w.def) {
                                            case EVar(vw) if (vw == elementAlias): makeASTWithMeta(EVar(binderName), w.metadata, w.pos);
                                            default: w;
                                        }
                                    });
                                    Sys.println('[ReduceAppendCanonicalize] fallback rebuilding acc concat with list=' + ElixirASTPrinter.print(listPrime, 0));
                                    newBody = [
                                        makeAST(EBinary(Match, makeAST(EVar(accName)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), listPrime])))),
                                        makeAST(EVar(accName))
                                    ];
                                }
                            }

                            var finalBody:ElixirAST = makeAST(EBlock(newBody));
                            var newFn = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: finalBody }]) );
                            makeASTWithMeta(ERemoteCall(modRef, "reduce", [listExpr, init, newFn]), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
