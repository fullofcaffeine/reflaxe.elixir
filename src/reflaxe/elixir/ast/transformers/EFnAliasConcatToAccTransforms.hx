package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

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
    static function isSelfAppend(rhs: ElixirAST, lhs: String): Bool {
        var result = false;
        ASTUtils.walk(rhs, function(n: ElixirAST) {
            if (result) return;
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
                                if (lhs != null && isSelfAppend(rhs, lhs)) {
                                    var replLeft = makeAST(EVar(accName));
                                    // Rebuild right, preserving list arg and replacing prefix with acc
                                    var newRight = ElixirASTTransformer.transformNode(rhs, function(z: ElixirAST): ElixirAST {
                                        return switch (z.def) {
                                            case ERemoteCall(_, "concat", argsX) if (argsX.length == 2):
                                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), argsX[1]]), z.metadata, z.pos);
                                            case ECall(_, "concat", argsCX) if (argsCX.length == 2):
                                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), argsCX[1]]), z.metadata, z.pos);
                                            case EBinary(Concat, _, r):
                                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), r]), z.metadata, z.pos);
                                            default:
                                                z;
                                        }
                                    });
                                    makeASTWithMeta(EBinary(Match, replLeft, newRight), stmt.metadata, stmt.pos);
                                } else stmt;
                            case EMatch(pat, rhs2):
                                var lhs2:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                                if (lhs2 != null && isSelfAppend(rhs2, lhs2)) {
                                    var newLeft = makeAST(EVar(accName));
                                    var newRight2 = ElixirASTTransformer.transformNode(rhs2, function(t2: ElixirAST): ElixirAST {
                                        return switch (t2.def) {
                                            case ERemoteCall(_, "concat", c2) if (c2.length == 2):
                                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), c2[1]]), t2.metadata, t2.pos);
                                            case ECall(_, "concat", cc2) if (cc2.length == 2):
                                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), cc2[1]]), t2.metadata, t2.pos);
                                            case EBinary(Concat, _, r2):
                                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), r2]), t2.metadata, t2.pos);
                                            default: t2;
                                        }
                                    });
                                    makeASTWithMeta(EBinary(Match, newLeft, newRight2), stmt.metadata, stmt.pos);
                                } else stmt;
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
