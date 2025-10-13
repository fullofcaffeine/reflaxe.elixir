package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceCanonicalize
 *
 * WHAT
 * - Unify alias-based accumulator self-appends inside two-arg anonymous reducer functions
 *   to canonical acc = Enum.concat(acc, list) shape. Also replaces head extraction using
 *   index 0 access with the reducer binder.
 *
 * WHY
 * - Lowerings may introduce temporary aliases for the accumulator (e.g., tmp = Enum.concat(tmp, ...))
 *   or extract head via list[0] even though the reducer binder already holds the current element.
 *   This causes warnings and non-idiomatic shapes.
 *
 * HOW
 * - For each EFn clause with exactly 2 parameters, derive:
 *   - binderName from the first arg when it is a PVar
 *   - accName from the second arg when it is a PVar
 * - Recurse the clause body and:
 *   1) Rewrite `lhs = Enum.concat(lhs, list)` to `acc = Enum.concat(acc, list)` when lhs matches acc alias
 *   2) Rewrite `x = some_list[0]` to `x = binder` (head extraction by access)
 * - Leaves tuples and complex patterns unchanged (conservative, shape-based, name-agnostic otherwise)
 *
 * EXAMPLES
 * Before:
 *   fn elem, acc ->
 *     tmp = Enum.concat(tmp, [elem])
 *     head = list[0]
 *     {:cont, {tmp}}
 *   end
 * After:
 *   fn elem, acc ->
 *     acc = Enum.concat(acc, [elem])
 *     head = elem
 *     {:cont, {acc}}
 *   end
 */
class ReduceCanonicalize {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var out = [];
                    for (cl in clauses) {
                        var binderName: Null<String> = null;
                        var accName: Null<String> = null;
                        if (cl.args != null && cl.args.length == 2) {
                            switch (cl.args[0]) { case PVar(nm): binderName = nm; default: }
                            switch (cl.args[1]) { case PVar(nm2): accName = nm2; default: }
                        }
                        var newBody = (binderName != null || accName != null)
                            ? rewriteBody(cl.body, binderName, accName)
                            : cl.body;
                        out.push({ args: cl.args, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(EFn(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST, binderName: Null<String>, accName: Null<String>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                // lhs = Enum.concat(lhs, list) → acc = Enum.concat(acc, list)
                case EBinary(Match, left, { def: ERemoteCall(_, "concat", cargs) }) if (accName != null && cargs != null && cargs.length == 2):
                    var lhsName: Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                    var isSelf = switch (cargs[0].def) { case EVar(n): (lhsName != null && n == lhsName); default: false; };
                    if (isSelf) {
                        var replLeft = makeAST(EVar(accName));
                        var replRight = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), cargs[1]]));
                        makeASTWithMeta(EBinary(Match, replLeft, replRight), x.metadata, x.pos);
                    } else x;
                // PVar = list[0] → PVar = binder
                case EMatch(pat, { def: EAccess(_, key) }) if (binderName != null):
                    var isZero = switch (key.def) { case EInteger(v) if (v == 0): true; default: false; };
                    if (isZero) makeASTWithMeta(EMatch(pat, makeAST(EVar(binderName))), x.metadata, x.pos) else x;
                default:
                    x;
            }
        });
    }
}

#end

