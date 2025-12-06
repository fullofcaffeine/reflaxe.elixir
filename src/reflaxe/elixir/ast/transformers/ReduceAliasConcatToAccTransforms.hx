package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceAliasConcatToAccTransforms
 *
 * WHAT
 * - Within Enum.reduce/3 anonymous functions, rewrite alias-based accumulator rebinds
 *   of the form `alias = Enum.concat(alias, [expr])` into canonical
 *   `acc = Enum.concat(acc, [expr])` using the reducer's second parameter name.
 *
 * WHY
 * - Some pipelines still leak a temporary alias name for the accumulator which is not declared
 *   in scope, causing undefined-variable errors in generated Elixir. Normalizing to the
 *   reducer accumulator fixes warnings-as-errors without relying on name heuristics.
 *
 * HOW
 * - Match `ERemoteCall(Enum, "reduce", [list, init, fn])` where `fn` has 2 args `(binder, acc)`.
 * - In the reducer body, replace any `EBinary(Match, EVar(lhs), ERemoteCall(_, "concat", [EVar(lhs), rhs]))`
 *   with `EBinary(Match, EVar(acc), ERemoteCall(EVar("Enum"), "concat", [EVar(acc), rhs]))`.
 * - Also supports `EMatch(PVar(lhs), ERemoteCall(...))` shape.
 *
 * EXAMPLES
 * Elixir (before):
 *   Enum.reduce(list, [], fn x, a -> alias = Enum.concat(alias, [x]) end)
 * Elixir (after):
 *   Enum.reduce(list, [], fn x, acc -> acc = Enum.concat(acc, [x]) end)
 */
class ReduceAliasConcatToAccTransforms {
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
                            var accName:Null<String> = switch (cl.args[1]) { case PVar(a): a; default: null; };
                            if (accName == null) return n;
                            var bodyStmts:Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                            var newBody:Array<ElixirAST> = [];
                            for (stmt in bodyStmts) {
                                var rewritten = switch (stmt.def) {
                                    case EBinary(Match, left, rhs):
                                        var lhs:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                                        switch (rhs.def) {
                                            case ERemoteCall(_, "concat", cargs) if (lhs != null && cargs.length == 2):
                                                var arg0Name:Null<String> = switch (cargs[0].def) { case EVar(nm2): nm2; default: null; };
                                                var isSelf = (arg0Name != null && arg0Name == lhs);
                                                if (isSelf) {
                                                    var replLeft = makeAST(EVar(accName));
                                                    var replRight = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), cargs[1]]));
                                                    makeASTWithMeta(EBinary(Match, replLeft, replRight), stmt.metadata, stmt.pos);
                                                } else stmt;
                                            case ERemoteCall(_, "concat", cargs) if (lhs != null):
                                                var arg0Dbg = switch (cargs[0].def) { case EVar(nm4): nm4; default: '<non-var>'; };
                                                stmt;
                                            default: stmt;
                                        }
                                    case EMatch(pat, rhs2):
                                        var lhs2:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                                        switch (rhs2.def) {
                                            case ERemoteCall(_, "concat", cargs2) if (lhs2 != null && cargs2.length == 2):
                                                var isSelf2 = switch (cargs2[0].def) { case EVar(nm3): (nm3 == lhs2); default: false; };
                                                if (isSelf2) {
                                                    var newLeft = makeAST(EVar(accName));
                                                    var newRight = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), cargs2[1]]));
                                                    makeASTWithMeta(EBinary(Match, newLeft, newRight), stmt.metadata, stmt.pos);
                                                } else stmt;
                                            default: stmt;
                                        }
                                    default:
                                        stmt;
                                };
                                newBody.push(rewritten);
                            }
                            var finalBody:ElixirAST = makeAST(EBlock(newBody));
                            var newFn = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: finalBody }]) );
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "reduce", [listExpr, init, newFn]), n.metadata, n.pos);
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
