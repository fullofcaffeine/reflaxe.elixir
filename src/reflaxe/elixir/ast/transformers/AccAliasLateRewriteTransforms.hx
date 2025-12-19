package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * AccAliasLateRewriteTransforms
 *
 * WHAT
 * - As a final safety-net, inside any anonymous function with two parameters `(binder, acc)`,
 *   rewrite accumulator alias self-append assignments
 *     alias = Enum.concat(alias, list)
 *     alias ++ list
 *   into canonical accumulator form
 *     acc = Enum.concat(acc, list)
 *   without relying on the surrounding reduce call shape.
 *
 * WHY
 * - Some pipelines generate reduce-like anonymous functions that are not recognized by earlier passes
 *   due to intervening wrappers or shape differences. This pass guarantees canonical accumulator updates
 *   before printing, eliminating undefined-local and hygiene warnings while adhering to idiomatic Elixir.
 *
 * HOW
 * - Traverse the AST with a lightweight context that tracks the current anonymous function's second
 *   parameter name when inside an `EFn` with at least two parameters.
 * - Whenever an assignment is encountered where the RHS structurally self-appends the LHS via
 *   `Enum.concat/2`, `concat/2`, or `++`, rewrite the assignment to target the acc parameter instead
 *   and normalize the RHS to `Enum.concat(acc, list)`.
 * - This is name-agnostic and strictly shape-based; it does not introduce new variables.
 *
 * EXAMPLES
 * Elixir (before):
 *   fn item, acc ->
 *     list = [item]
 *     alias = Enum.concat(alias, list)
 *   end
 * Elixir (after):
 *   fn item, acc ->
 *     list = [item]
 *     acc = Enum.concat(acc, list)
 *   end
 */
class AccAliasLateRewriteTransforms {
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

    static function rewriteToAcc(lhsName: String, rhs: ElixirAST, accName: String, meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
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
        return makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), newRight), meta, pos);
    }

    static function transformWithAccContext(ast: ElixirAST, currentAcc: Null<String>): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses) if (clauses.length == 1):
                    var cl = clauses[0];
                    if (cl.args.length < 2) return n;
                    var accName:Null<String> = switch (cl.args[1]) { case PVar(a): a; default: null; };
                    if (accName == null) return n;
                    var newBody = transformWithAccContext(cl.body, accName);
                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]), n.metadata, n.pos);
                case EBinary(Match, left, rhs) if (currentAcc != null):
                    var lhsName:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                    if (lhsName != null && isSelfAppend(rhs, lhsName)) {
                        rewriteToAcc(lhsName, rhs, currentAcc, n.metadata, n.pos);
                    } else n;
                case EMatch(pat, rhs2) if (currentAcc != null):
                    var lhsName2:Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
                    if (lhsName2 != null && isSelfAppend(rhs2, lhsName2)) {
                        rewriteToAcc(lhsName2, rhs2, currentAcc, n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return transformWithAccContext(ast, null);
    }
}

#end
