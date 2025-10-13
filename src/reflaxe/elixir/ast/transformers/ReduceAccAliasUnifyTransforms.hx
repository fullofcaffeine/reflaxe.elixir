package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceAccAliasUnifyTransforms
 *
 * WHAT
 * - Inside `Enum.reduce(list, init, fn binder, acc -> ... end)`, detect a single accumulator alias
 *   (a local variable repeatedly assigned via `alias = Enum.concat(alias, [expr])`) and unify all
 *   occurrences of that alias to `acc` within the reducer body.
 *
 * WHY
 * - Generated code sometimes uses a temporary alias for the accumulator (e.g., `todo_items`, `tag_elements`).
 *   This creates unbound local warnings/errors. Unifying to `acc` restores canonical reducer form.
 *
 * HOW
 * - For each reduce EFn with 2 args (binder, acc):
 *   1) Scan the body for assignments `EBinary(Match, EVar(lhs), ERemoteCall(_, "concat", [EVar(lhs), ...]))`.
 *   2) If exactly one distinct `lhs` (alias) exists and it is not `acc`, rename all `EVar(lhs)` to `acc` in body.
 *   3) Rebuild the reduce call with the unified function body.
 */
class ReduceAccAliasUnifyTransforms {
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
                            if (accName == null) return n;
                            // Collect alias candidates
                            var aliasSet = new Map<String,Bool>();
                            ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                                switch (x.def) {
                                    case EBinary(Match, left, rhs):
                                        var lhs:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                                        switch (rhs.def) {
                                            case ERemoteCall(_, "concat", cargs) if (lhs != null && cargs.length == 2):
                                                switch (cargs[0].def) { case EVar(nm2) if (nm2 == lhs && lhs != accName): aliasSet.set(lhs, true); default: }
                                            default:
                                        }
                                    case EMatch(pat, rhs2):
                                        var lhs2:Null<String> = switch (pat) { case PVar(n2): n2; default: null; };
                                        switch (rhs2.def) {
                                            case ERemoteCall(_, "concat", cargs2) if (lhs2 != null && cargs2.length == 2):
                                                switch (cargs2[0].def) { case EVar(nm3) if (nm3 == lhs2 && lhs2 != accName): aliasSet.set(lhs2, true); default: }
                                            default:
                                        }
                                    default:
                                }
                                return x;
                            });
                            // Unify all discovered aliases (one or more) to acc across reducer body
                            var aliases = [for (k in aliasSet.keys()) k];
                            if (aliases.length == 0) return n;
                            var newBody = ElixirASTTransformer.transformNode(cl.body, function(y: ElixirAST): ElixirAST {
                                return switch (y.def) {
                                    case EVar(v) if (aliases.indexOf(v) != -1): makeASTWithMeta(EVar(accName), y.metadata, y.pos);
                                    default: y;
                                }
                            });
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
