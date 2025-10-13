package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnAliasConcatToAccTransforms
 *
 * WHAT
 * - Inside any single-clause anonymous function with two parameters `(binder, acc)`,
 *   rewrite alias-based rebinds of the form `alias = Enum.concat(alias, [expr])` to
 *   `acc = Enum.concat(acc, [expr])`.
 *
 * WHY
 * - Some reduce-like constructs can be introduced by different passes or not recognized as
 *   ERemoteCall(Enum, "reduce", ...). This pass provides a structural safety net keyed only
 *   on the two-arg accumulator function shape to normalize accumulator usage.
 *
 * HOW
 * - Match `EFn([{ args, body }])` where `args.length >= 2` and args[1] is `PVar(acc)`.
 * - Process the body statements; if any statement matches
 *     `EBinary(Match, EVar(lhs), ERemoteCall(_, "concat", [EVar(lhs), rhs]))`
 *   or
 *     `EMatch(PVar(lhs), ERemoteCall(_, "concat", [EVar(lhs), rhs]))`
 *   rewrite lhs to acc on both sides.
 */
class EFnAliasConcatToAccTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
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
                                        var arg0IsLhs = switch (cargs[0].def) { case EVar(nm2): (nm2 == lhs); default: false; };
                                        if (arg0IsLhs) {
                                            var replLeft = makeAST(EVar(accName));
                                            var replRight = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), cargs[1]]));
                                            makeASTWithMeta(EBinary(Match, replLeft, replRight), stmt.metadata, stmt.pos);
                                        } else stmt;
                                    default: stmt;
                                }
                            case EMatch(pat, rhs2):
                                var lhs2:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                                switch (rhs2.def) {
                                    case ERemoteCall(_, "concat", cargs2) if (lhs2 != null && cargs2.length == 2):
                                        var arg0IsLhs2 = switch (cargs2[0].def) { case EVar(nm3): (nm3 == lhs2); default: false; };
                                        if (arg0IsLhs2) {
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
                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: finalBody }]), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

