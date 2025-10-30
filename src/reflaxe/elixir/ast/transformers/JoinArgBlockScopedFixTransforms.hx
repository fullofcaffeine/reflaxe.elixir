package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * JoinArgBlockScopedFixTransforms
 *
 * WHAT
 * - Repairs Enum.join first-argument shapes when the list is built via a
 *   canonical temp-list builder sequence in the same surrounding block
 *   (initializer → Enum.each(concat) → return temp), but passed to join
 *   as a bare variable (not an inline block).
 *
 * WHY
 * - Earlier rewrites (JoinArgListBuilderToMapJoin) handle the inline-block
 *   form directly in the argument position. Some desugarings instead emit
 *   sibling statements in the enclosing block and pass the accumulator
 *   variable to Enum.join, which leaks raw statements into interpolation or
 *   leaves non-idiomatic concatenation patterns in late stages.
 *   Rewriting to Enum.map |> Enum.join yields a single valid expression and
 *   removes builder noise.
 *
 * HOW
 * - When visiting an EBlock, scan its statements for a call of the form
 *   Enum.join(accVar, sep). If found, search the immediate preceding sibling
 *   window for the canonical builder pattern:
 *     accVar = [];
 *     Enum.each(list, fn item -> accVar = Enum.concat(accVar, [value]) end);
 *     accVar
 *   If matched and contiguous, replace the join call’s first argument with
 *   Enum.map(list, fn item -> value end), remove the builder subsequence, and
 *   keep the join call. If the subsequence is not contiguous, only rewrite the
 *   argument and keep original statements (conservative, semantics-preserving).
 *
 * EXAMPLES
 * Haxe (canonical builder):
 *   var acc = [];
 *   for (x in xs) acc = acc.concat([f(x)]);
 *   return acc.join(",");
 * Elixir (after):
 *   Enum.join(Enum.map(xs, fn x -> f(x) end), ",")
 */
class JoinArgBlockScopedFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    fixBlock(stmts, n);
                default:
                    n;
            }
        });
    }

    static function fixBlock(stmts: Array<ElixirAST>, original: ElixirAST): ElixirAST {
        var updated: Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
            var current = stmts[i];
            var handled = false;
            switch (current.def) {
                case ERemoteCall({def: EVar("Enum")}, "join", joinArgs) if (joinArgs != null && joinArgs.length == 2):
                    var accVarName = extractVarName(joinArgs[0]);
                    if (accVarName != null) {
                        var match = findBuilderWindow(stmts, i, accVarName);
                        if (match != null) {
                            var mapExpr = buildEnumMap(match.listExpr, match.binderName, match.valueExpr);
                            var newJoin = makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [mapExpr, joinArgs[1]]));
                            // Remove contiguous builder window if safe and contiguous
                            var didRemove = false;
                            if (match.isContiguous) {
                                // push all statements up to start (exclusive)
                                for (k in 0...match.startIndex) updated.push(stmts[k]);
                                // replace current position with rewritten join
                                updated.push(newJoin);
                                // skip past the original window and the current join
                                i = match.endIndex + 1; // endIndex is last index of builder window
                                handled = true;
                                didRemove = true;
                            }
                            if (!didRemove) {
                                // Only rewrite arg; keep statements untouched
                                updated.push(newJoin);
                                i++;
                                handled = true;
                            }
                        }
                    }
                default:
            }
            if (!handled) {
                updated.push(current);
                i++;
            }
        }
        return makeASTWithMeta(EBlock(updated), original.metadata, original.pos);
    }

    static function extractVarName(ast: ElixirAST): Null<String> {
        return switch (ast.def) {
            case EVar(n): n;
            case EParen(inner): extractVarName(inner);
            default: null;
        }
    }

    private static function buildEnumMap(listExpr: ElixirAST, binderName: String, valueExpr: ElixirAST): ElixirAST {
        var fnNode = makeAST(EFn([{ args: [PVar(binderName)], guard: null, body: valueExpr }]));
        return makeAST(ERemoteCall(makeAST(EVar("Enum")), "map", [listExpr, fnNode]));
    }

    private static function findBuilderWindow(stmts: Array<ElixirAST>, joinIndex: Int, accName: String): Null<{startIndex:Int, endIndex:Int, listExpr: ElixirAST, binderName:String, valueExpr: ElixirAST, isContiguous:Bool}> {
        // Expect a sequence: [initAcc], [Enum.each(list, fn binder -> acc = Enum.concat(acc, [value]) end)], [acc]
        var initIndex = -1;
        var eachIndex = -1;
        var returnIndex = -1;
        var listExpr: Null<ElixirAST> = null;
        var binderName = "item";
        var valueExpr: Null<ElixirAST> = null;

        // Search backwards up to three statements preceding join
        var startScan = Std.int(Math.max(0, joinIndex - 3));
        for (idx in startScan...joinIndex) switch (stmts[idx].def) {
            case EBinary(Match, {def: EVar(v)}, {def: EList([])}) if (v == accName):
                initIndex = idx;
            case EMatch(PVar(v2), {def: EList([])}) if (v2 == accName):
                initIndex = idx;
            case ERemoteCall({def: EVar("Enum")}, "each", eargs) if (eargs != null && eargs.length == 2):
                var maybeList = eargs[0];
                switch (eargs[1].def) {
                    case EFn(clauses) if (clauses.length == 1):
                        var clause = clauses[0];
                        switch (clause.args.length > 0 ? clause.args[0] : null) { case PVar(n): binderName = n; default: }
                        var bodyStmts: Array<ElixirAST> = switch (clause.body.def) { case EBlock(ss): ss; default: [clause.body]; };
                        for (bs in bodyStmts) switch (bs.def) {
                            case EBinary(Match, {def: EVar(lhs)}, rhs) if (lhs == accName):
                                switch (rhs.def) {
                                    case ERemoteCall({def: EVar("Enum")}, "concat", cargs) if (cargs.length == 2):
                                        switch (cargs[1].def) { case EList(items) if (items.length == 1): valueExpr = items[0]; default: }
                                    case EBinary(Concat, {def: EVar(base)}, rhsAppend) if (base == accName):
                                        // Accept acc = acc ++ [value]
                                        switch (rhsAppend.def) { case EList(items2) if (items2.length == 1): valueExpr = items2[0]; default: }
                                    default:
                                }
                            default:
                        }
                        if (valueExpr != null) {
                            eachIndex = idx; listExpr = maybeList;
                        }
                    default:
                }
            case EVar(vret) if (vret == accName):
                returnIndex = idx;
            default:
        }

        if (initIndex == -1 || eachIndex == -1) return null;
        if (listExpr == null || valueExpr == null) return null;

        var startIndex = initIndex;
        var endIndex = returnIndex != -1 ? returnIndex : eachIndex;
        var isContiguous = (startIndex + 1 == eachIndex) && (returnIndex == -1 || eachIndex + 1 == returnIndex) && (endIndex < joinIndex);
        return { startIndex: startIndex, endIndex: endIndex, listExpr: listExpr, binderName: binderName, valueExpr: valueExpr, isContiguous: isContiguous };
    }
}

#end

