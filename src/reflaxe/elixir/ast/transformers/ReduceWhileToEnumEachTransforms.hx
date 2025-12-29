package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileToEnumEachTransforms
 *
 * WHAT
 * - Rewrites trivial Stream.iterate(0, ...) + Enum.reduce_while list scans into
 *   Enum.each(list, fn elem -> ... end), removing sentinel numeric statements
 *   and non-semantic cont/halt scaffolding.
 *
 * WHY
 * - Loop-lowering emits reduce_while constructs with bare numeric literal
 *   statements (1) inside bodies purely to maintain shape, which causes
 *   warnings and is non-idiomatic in Elixir.
 *
 * HOW
 * - Detect pattern:
 *   Enum.reduce_while(Stream.iterate(0, _), {listVar}, fn _, {listVar} ->
 *     if 0 < length(listVar) do
 *       elemVar = listVar[0]
 *       1
 *       ...body...
 *       {:cont, {listVar}}
 *     else
 *       {:halt, {listVar}}
 *     end
 *   end)
 * - Rewrite to: Enum.each(listVar, fn elemVar -> ...body... end) by:
 *   - Dropping the `if` wrapper (Enum.each already handles empty lists)
 *   - Removing `elemVar = listVar[0]` (elemVar becomes the fn binder)
 *   - Filtering out standalone literal sentinel statements and {:cont/:halt} scaffolding

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ReduceWhileToEnumEachTransforms {
    static function isStreamIterateZero(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar("Stream")}, "iterate", _): true;
            default: false;
        };
    }

    static function filterSentinelStmts(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        for (s in stmts) {
            var keep = true;
            switch (s.def) {
                case EInteger(v) if (v == 1 || v == 0): keep = false;
                case ETuple(elements):
                    // Drop {:cont, {...}} / {:halt, {...}}
                    if (elements.length >= 1) switch (elements[0].def) {
                        case EAtom(name) if (name == "cont" || name == "halt"): keep = false;
                        default:
                    }
                default:
            }
            if (keep) out.push(s);
        }
        return out;
    }

    static function unwrapSingletonBlock(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length != 1) return stmts;
        var only = stmts[0];
        if (only == null || only.def == null) return stmts;
        return switch (only.def) {
            case EBlock(inner): inner;
            case EDo(inner2): inner2;
            default: stmts;
        };
    }

    static function extractElementBinder(stmts: Array<ElixirAST>, listVarName: String): Null<{ binder: String, remaining: Array<ElixirAST> }> {
        if (stmts == null || stmts.length == 0) return null;
        var remaining = stmts.copy();
        for (i in 0...remaining.length) {
            var s = remaining[i];
            if (s == null || s.def == null) continue;

            var binder: Null<String> = switch (s.def) {
                case EBinary(Match, {def: EVar(lhs)}, rhs):
                    lhs != null && rhs != null && isListHeadAccess(rhs, listVarName) ? lhs : null;
                case EMatch(PVar(lhs2), rhs2):
                    lhs2 != null && rhs2 != null && isListHeadAccess(rhs2, listVarName) ? lhs2 : null;
                default:
                    null;
            };

            if (binder != null) {
                remaining.splice(i, 1);
                return { binder: binder, remaining: remaining };
            }
        }
        return null;
    }

    static function isListHeadAccess(expr: ElixirAST, listVarName: String): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (expr.def) {
            case EAccess({def: EVar(v)}, {def: EInteger(i)}) if (v == listVarName && i == 0):
                true;
            case ERemoteCall({def: EVar("Enum")}, "at", args)
                if (args != null && args.length >= 2):
                switch (args[0].def) {
                    case EVar(v2) if (v2 == listVarName):
                        switch (args[1].def) { case EInteger(i2) if (i2 == 0): true; default: false; }
                    default:
                        false;
                }
            default:
                false;
        };
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar("Enum")}, "reduce_while", args) if (args != null && args.length == 3 && isStreamIterateZero(args[0])):
                    // Expect accumulator as single-tuple {listVar}
                    var listExpr: Null<ElixirAST> = null;
                    var listVarName: Null<String> = null;
                    switch (args[1].def) {
                        case ETuple(items) if (items.length == 1):
                            listExpr = items[0];
                        default:
                    }
                    if (listExpr == null) return n;
                    switch (listExpr.def) {
                        case EVar(vn): listVarName = vn;
                        default:
                    }
                    if (listVarName == null) return n;
                    // Reducer function
                    var reducer = args[2];
                    // Attempt to extract body from reducer by looking for if ... do/end blocks and filtering sentinels
                    var bodyBlock: Null<ElixirAST> = null;
                    var elementBinder: Null<String> = null;
                    switch (reducer.def) {
                        case EFn(clauses) if (clauses.length >= 1):
                            var b = clauses[0].body;
                            // Usually an if with do/end (EIf with EBlock branches)
                            switch (b.def) {
                                case EIf(_, thenBr, elseBr):
                                    var thenStmts: Array<ElixirAST> = [];
                                    switch (thenBr.def) {
                                        case EBlock(sts): thenStmts = sts;
                                        default:
                                            thenStmts = [thenBr];
                                    }
                                    thenStmts = unwrapSingletonBlock(thenStmts);
                                    var filtered = filterSentinelStmts(thenStmts);
                                    filtered = unwrapSingletonBlock(filtered);
                                    var extracted = extractElementBinder(filtered, listVarName);
                                    if (extracted != null) {
                                        elementBinder = extracted.binder;
                                        filtered = extracted.remaining;
                                    } else {
                                        #if debug_reduce_while_to_each
                                        #if sys
                                        Sys.println('[ReduceWhileToEnumEach] no elem binder for listVar=' + listVarName + ' thenStmts=' + filtered.length);
                                        var limit = filtered.length < 6 ? filtered.length : 6;
                                        for (i in 0...limit) {
                                            var st = filtered[i];
                                            var tag = (st == null || st.def == null) ? '<null>' : reflaxe.elixir.util.EnumReflection.enumConstructor(st.def);
                                            Sys.println('  stmt[' + i + '] ' + tag);
                                            if (st != null) switch (st.def) {
                                                case EBlock(inner):
                                                    Sys.println('    block.len=' + (inner == null ? 0 : inner.length));
                                                    if (inner != null && inner.length > 0 && inner[0] != null && inner[0].def != null) {
                                                        Sys.println('    block[0]=' + reflaxe.elixir.util.EnumReflection.enumConstructor(inner[0].def));
                                                    }
                                                case EBinary(Match, left, rhs):
                                                    var lt = left == null || left.def == null ? '<null>' : reflaxe.elixir.util.EnumReflection.enumConstructor(left.def);
                                                    var rt = rhs == null || rhs.def == null ? '<null>' : reflaxe.elixir.util.EnumReflection.enumConstructor(rhs.def);
                                                    Sys.println('    lhs=' + lt + ' rhs=' + rt);
                                                case EMatch(_, rhsExpr):
                                                    var rhsTag = rhsExpr == null || rhsExpr.def == null ? '<null>' : reflaxe.elixir.util.EnumReflection.enumConstructor(rhsExpr.def);
                                                    Sys.println('    rhs=' + rhsTag);
                                                default:
                                            }
                                        }
                                        Sys.stdout().flush();
                                        #end
                                        #end
                                    }
                                    bodyBlock = makeAST(EBlock(filtered.length > 0 ? filtered : [makeAST(ENil)]));
                                default:
                            }
                        default:
                    }
                    if (bodyBlock == null || elementBinder == null) return n;
                    // Build Enum.each(listExpr, fn <elem> -> filtered end)
                    var eachFnClause: EFnClause = {
                        args: [ PVar(elementBinder) ],
                        guard: null,
                        body: bodyBlock
                    };
                    var eachFn = makeAST(EFn([eachFnClause]));
                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "each", [listExpr, eachFn]), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
