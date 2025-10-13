package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ASTUtils;

/**
 * ReduceAccAliasUnifyTransforms
 *
 * WHAT
 * - Inside `Enum.reduce(list, init, fn binder, acc -> ... end)`, canonicalize two late reducer aliasing patterns:
 *   (1) Accumulator alias self-append: `alias = Enum.concat(alias, [elem])` or `alias ++ [elem]` or `concat(alias, [...])`
 *       → unify all `alias` refs and rebinds to the accumulator param `acc`.
 *   (2) Binder aliasing: `binderAlias = binder` (or pattern form) → replace `binderAlias` usages with the reducer's
 *       first parameter `binder`.
 *
 * WHY
 * - The pipeline may leave readable but non-canonical aliases in late stages (e.g., `todo_items` for `acc`, `todo` for
 *   `entry`). These cause hygiene issues and warnings, and obscure the idiomatic reduce shape. Unifying eliminates the
 *   aliases without inventing APIs and preserves semantics.
 *
 * HOW
 * - For each reduce EFn with 2 args (binder, acc):
 *   1) Scan the body for assignments whose RHS self-appends the LHS via `Enum.concat/2`, `concat/2`, or `++`.
 *      Collect these LHS names as accumulator aliases (excluding the real `acc`).
 *   2) Scan the body for trivial binder alias rebinds: `alias = binder` or `EMatch(PVar(alias), EVar(binder))` and
 *      collect `alias` as binder aliases (excluding the real `binder`).
 *   3) Rewrite body:
 *      - Replace `EVar(alias)` with `acc` (for acc aliases) or `binder` (for binder aliases).
 *      - For alias assignments, drop the rebind by rewriting to the RHS expression (keeps value semantics without
 *        introducing sentinels) and still perform var replacement recursively.
 *   4) Emit updated reducer with unified body. Keep as an absolute-late pass so it harmonizes previous rewrites.
 *
 * EXAMPLES
 * Haxe:
 *   for (todo in todos) acc.push(render(todo));
 * Elixir (before):
 *   Enum.reduce(todos, [], fn entry, acc ->
 *     todo = entry
 *     todo_items = Enum.concat(todo_items, [render_todo_item(todo)])
 *     acc
 *   end)
 * Elixir (after):
 *   Enum.reduce(todos, [], fn entry, acc ->
 *     acc = Enum.concat(acc, [render_todo_item(entry)])
 *     acc
 *   end)
 */
class ReduceAccAliasUnifyTransforms {
    static function isSelfAppend(rhs: ElixirAST, lhs: String): Bool {
        var result = false;
        ASTUtils.walk(rhs, function(n: ElixirAST) {
            if (result) return; // early out
            switch (n.def) {
                case ERemoteCall(_, "concat", args) if (args.length == 2):
                    switch (args[0].def) { case EVar(nm) if (nm == lhs): result = true; default: }
                case ECall(_, "concat", argsC) if (argsC.length == 2):
                    switch (argsC[0].def) { case EVar(nm2) if (nm2 == lhs): result = true; default: }
                case EBinary(Concat, l, _):
                    switch (l.def) { case EVar(nm3) if (nm3 == lhs): result = true; default: }
                default:
            }
        });
        return result;
    }
    public static function unifyPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, "reduce", args) if (args.length == 3):
                    var fnNode = args[2];
                    switch (fnNode.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var cl = clauses[0];
                            if (cl.args.length < 2) return n;
                            var accName:Null<String> = switch (cl.args[1]) { case PVar(a): a; default: null; };
                            var binderName:Null<String> = switch (cl.args[0]) { case PVar(b): b; default: null; };
                            if (accName == null) return n;
                            #if debug_reduce_unify
                            Sys.println('[ReduceAccAliasUnify] reduce fn body before=\n' + ElixirASTPrinter.print(cl.body, 0));
                            #end
                            // Collect alias candidates
                            var accAliasSet = new Map<String,Bool>();
                            var binderAliasSet = new Map<String,Bool>();
                            ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                                switch (x.def) {
                                    case EBinary(Match, left, rhs):
                                        #if debug_reduce_unify
                                        Sys.println('[ReduceAccAliasUnify][scan] match lhs=' + ElixirASTPrinter.print(left, 0) + ' rhs=' + ElixirASTPrinter.print(rhs, 0));
                                        #end
                                        var lhs:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                                        if (lhs != null) {
                                            if (isSelfAppend(rhs, lhs) && lhs != accName) {
                                                accAliasSet.set(lhs, true);
                                                Sys.println('[ReduceAccAliasUnify] acc alias: ' + lhs + ' (acc=' + accName + ')');
                                            }
                                            switch (rhs.def) {
                                                case EVar(rv) if (binderName != null && rv == binderName && lhs != binderName):
                                                    binderAliasSet.set(lhs, true);
                                                    Sys.println('[ReduceAccAliasUnify] binder alias: ' + lhs + ' (binder=' + binderName + ')');
                                                default:
                                            }
                                        }
                                    case EMatch(pat, rhs2):
                                        #if debug_reduce_unify
                                        Sys.println('[ReduceAccAliasUnify][scan] ematch rhs=' + ElixirASTPrinter.print(rhs2, 0));
                                        #end
                                        var lhs2:Null<String> = switch (pat) { case PVar(n2): n2; default: null; };
                                        if (lhs2 != null) {
                                            if (isSelfAppend(rhs2, lhs2) && lhs2 != accName) {
                                                accAliasSet.set(lhs2, true);
                                                Sys.println('[ReduceAccAliasUnify] acc alias: ' + lhs2 + ' (acc=' + accName + ')');
                                            }
                                            switch (rhs2.def) {
                                                case EVar(rv2) if (binderName != null && rv2 == binderName && lhs2 != binderName):
                                                    binderAliasSet.set(lhs2, true);
                                                    Sys.println('[ReduceAccAliasUnify] binder alias: ' + lhs2 + ' (binder=' + binderName + ')');
                                                default:
                                            }
                                        }
                                    default:
                                }
                                return x;
                            });
                            // Unify all discovered aliases (one or more) to acc across reducer body
                            var accAliases = [for (k in accAliasSet.keys()) k];
                            var binderAliases = [for (k in binderAliasSet.keys()) k];
                            Sys.println('[ReduceAccAliasUnify] reducer acc=' + accName + (binderName != null ? (', binder=' + binderName) : '') + ', accAliases=' + accAliases.length + ', binderAliases=' + binderAliases.length);
                            if (accAliases.length == 0 && binderAliases.length == 0) return n;
                            var newBody = ElixirASTTransformer.transformNode(cl.body, function(y: ElixirAST): ElixirAST {
                                return switch (y.def) {
                                    case EVar(v):
                                        if (accAliases.indexOf(v) != -1) {
                                            makeASTWithMeta(EVar(accName), y.metadata, y.pos);
                                        } else if (binderName != null && binderAliases.indexOf(v) != -1) {
                                            makeASTWithMeta(EVar(binderName), y.metadata, y.pos);
                                        } else {
                                            y;
                                        }
                                    case EBinary(Match, left, rhs):
                                        var isAccAliasLhs = switch (left.def) { case EVar(vl) if (accAliases.indexOf(vl) != -1): true; default: false; };
                                        var isBinderAliasLhs = switch (left.def) { case EVar(vl2) if (binderAliases.indexOf(vl2) != -1): true; default: false; };
                                        if (isAccAliasLhs) {
                                            var newLeft = makeAST(EVar(accName));
                                            makeASTWithMeta(EBinary(Match, newLeft, rhs), y.metadata, y.pos);
                                        } else if (isBinderAliasLhs) {
                                            // Drop trivial alias rebind by returning RHS (preserves value semantics)
                                            rhs;
                                        } else {
                                            y;
                                        }
                                    case EMatch(pat, rhs2):
                                        var isAccAliasPat = switch (pat) { case PVar(vp) if (accAliases.indexOf(vp) != -1): true; default: false; };
                                        var isBinderAliasPat = switch (pat) { case PVar(vp2) if (binderAliases.indexOf(vp2) != -1): true; default: false; };
                                        if (isAccAliasPat) {
                                            makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), rhs2), y.metadata, y.pos);
                                        } else if (isBinderAliasPat) {
                                            // Drop trivial alias rebind by returning RHS
                                            rhs2;
                                        } else {
                                            y;
                                        }
                                    default:
                                        y;
                                }
                            });
                            #if debug_reduce_unify
                            Sys.println('[ReduceAccAliasUnify] reduce fn body after=\n' + ElixirASTPrinter.print(newBody, 0));
                            #end
                            var newFn = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: newBody }]) );
                            makeASTWithMeta(ERemoteCall(mod, "reduce", [args[0], args[1], newFn]), n.metadata, n.pos);
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
