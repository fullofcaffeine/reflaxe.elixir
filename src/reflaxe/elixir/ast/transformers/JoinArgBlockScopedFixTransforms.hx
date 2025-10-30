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
            // Try to repair a join call nested anywhere inside this statement
            var matchedWindow: Null<{startIndex:Int, endIndex:Int, listExpr: ElixirAST, binderName:String, valueExpr: ElixirAST, isContiguous:Bool}> = null;
            var sepArg: Null<ElixirAST> = null;
            var repairedCurrent = ElixirASTTransformer.transformNode(current, function(m: ElixirAST): ElixirAST {
                return switch (m.def) {
                    case ERemoteCall({def: EVar("Enum")}, "join", joinArgs) if (joinArgs != null && joinArgs.length == 2 && matchedWindow == null):
                        var accVarName = extractVarName(joinArgs[0]);
                        var win = (accVarName != null) ? findBuilderWindow(stmts, i, accVarName) : null;
                        if (win == null) win = findBuilderWindow(stmts, i, null);
                        if (win != null) {
                            matchedWindow = win;
                            sepArg = joinArgs[1];
                            var mapExpr = buildEnumMap(win.listExpr, win.binderName, win.valueExpr);
                            makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [mapExpr, joinArgs[1]]));
                        } else m;
                    default:
                        m;
                }
            });
            if (matchedWindow != null) {
                var didRemove = false;
                if (matchedWindow.isContiguous) {
                    for (k in 0...matchedWindow.startIndex) updated.push(stmts[k]);
                    updated.push(repairedCurrent);
                    i = matchedWindow.endIndex + 1;
                    handled = true;
                    didRemove = true;
                }
                if (!didRemove) {
                    updated.push(repairedCurrent);
                    i++;
                    handled = true;
                }
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

    private static function findBuilderWindow(stmts: Array<ElixirAST>, joinIndex: Int, accName: Null<String>): Null<{startIndex:Int, endIndex:Int, listExpr: ElixirAST, binderName:String, valueExpr: ElixirAST, isContiguous:Bool}> {
        // Expect a sequence: [initAcc], [Enum.each(list, fn binder -> acc = Enum.concat(acc, [value]) end)], [acc]
        var initIndex = -1;
        var eachIndex = -1;
        var returnIndex = -1;
        var listExpr: Null<ElixirAST> = null;
        var binderName = "item";
        var valueExpr: Null<ElixirAST> = null;
        var accDetected: Null<String> = accName;

        // Search backwards up to three statements preceding join
        var startScan = Std.int(Math.max(0, joinIndex - 3));
        for (idx in startScan...joinIndex) switch (stmts[idx].def) {
            case EBinary(Match, {def: EVar(v)}, {def: EList([])}):
                if (accDetected == null || v == accDetected) { initIndex = idx; if (accDetected == null) accDetected = v; }
            case EMatch(PVar(v2), {def: EList([])}):
                if (accDetected == null || v2 == accDetected) { initIndex = idx; if (accDetected == null) accDetected = v2; }
            case ERemoteCall({def: EVar("Enum")}, "each", eargs) if (eargs != null && eargs.length == 2):
                var maybeList = eargs[0];
                switch (eargs[1].def) {
                    case EFn(clauses) if (clauses.length == 1):
                        var clause = clauses[0];
                        switch (clause.args.length > 0 ? clause.args[0] : null) { case PVar(n): binderName = n; default: }
                        var bodyStmts: Array<ElixirAST> = switch (clause.body.def) { case EBlock(ss): ss; default: [clause.body]; };
                        for (bs in bodyStmts) switch (bs.def) {
                            case EBinary(Match, {def: EVar(lhs)}, rhs) if (accDetected != null && lhs == accDetected):
                                switch (rhs.def) {
                                    case ERemoteCall({def: EVar("Enum")}, "concat", cargs) if (cargs.length == 2):
                                        switch (cargs[1].def) { case EList(items) if (items.length == 1): valueExpr = items[0]; default: }
                                    case EBinary(Concat, {def: EVar(base)}, rhsAppend) if (accDetected != null && base == accDetected):
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
            case EVar(vret) if (accDetected != null && vret == accDetected):
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
