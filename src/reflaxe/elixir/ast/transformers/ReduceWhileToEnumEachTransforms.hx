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
 * - Rewrite to: Enum.each(listVar, fn _elem -> ...body... end), filtering out
 *   standalone literal 1 statements and {:cont/:halt} scaffolding.
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

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar("Enum")}, "reduce_while", args) if (args != null && args.length == 3 && isStreamIterateZero(args[0])):
                    // Expect accumulator as single-tuple {listVar}
                    var listExpr: Null<ElixirAST> = null;
                    switch (args[1].def) {
                        case ETuple(items) if (items.length == 1):
                            listExpr = items[0];
                        default:
                    }
                    if (listExpr == null) return n;
                    // Reducer function
                    var reducer = args[2];
                    // Attempt to extract body from reducer by looking for if ... do/end blocks and filtering sentinels
                    var bodyBlock: Null<ElixirAST> = null;
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
                                    var filtered = filterSentinelStmts(thenStmts);
                                    bodyBlock = makeAST(EBlock(filtered));
                                default:
                            }
                        default:
                    }
                    if (bodyBlock == null) return n;
                    // Build Enum.each(listExpr, fn _elem -> filtered end)
                    var eachFnClause: EFnClause = {
                        args: [ PVar("_elem") ],
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

