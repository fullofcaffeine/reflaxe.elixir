package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * JoinArgListBuilderToMapJoinTransforms
 *
 * WHAT
 * - Rewrites Enum.join(<block that builds temp list>, sep) into
 *   Enum.map(list, fn item -> expr end) |> Enum.join(sep).
 *
 * WHY
 * - In many desugarings (especially inside string interpolation), the list
 *   used for Enum.join is constructed inline via a block:
 *     temp = [];
 *     Enum.each(list, fn item -> temp = Enum.concat(temp, [expr]) end);
 *     temp
 *   This produces invalid syntax when printed raw as a function argument.
 *   Rewriting to Enum.map |> Enum.join yields idiomatic and valid Elixir.
 *
 * HOW
 * - Match ERemoteCall(Enum, "join", [arg1, sep]) where arg1 is an EBlock
 *   that initializes a temp list, performs Enum.each with concat to temp,
 *   then returns temp as its final expression. Synthesize Enum.map(list, fn ->
 *   expr end) and pipe into Enum.join(sep).
 */
class JoinArgListBuilderToMapJoinTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, "join", args) if (args != null && args.length == 2):
                    switch (mod.def) {
                        case EVar(m) if (m == "Enum"):
                            var block = args[0];
                            var sep = args[1];
                            var rewrite = tryRewriteJoinArgBlock(block);
                            if (rewrite != null) {
                                // pipe: Enum.map(list, fn ...) |> Enum.join(sep)
                                var mapCall = rewrite;
                                var joinCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [mapCall, sep]));
                                makeASTWithMeta(joinCall.def, n.metadata, n.pos);
                            } else {
                                // Fallback: if arg[0] is a multi-statement block, wrap it as an IIFE to make it a valid expression
                                switch (block.def) {
                                    case EBlock(_):
                                        var iife = makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: block }])), "", []));
                                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "join", [iife, sep]), n.metadata, n.pos);
                                    default:
                                        n;
                                }
                            }
                        default:
                            n;
                    }
                case ECall(target, "join", args) if (args != null && args.length == 1 && target != null):
                    // Handle instance-style list.join(sep) before InstanceMethodTransform runs
                    var listLike = target;
                    var sep1 = args[0];
                    // If receiver is a block that builds a list, rewrite to Enum.map |> Enum.join
                    var rewrite2 = tryRewriteJoinArgBlock(listLike);
                    if (rewrite2 != null) {
                        var joinCall2 = makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [rewrite2, sep1]));
                        makeASTWithMeta(joinCall2.def, n.metadata, n.pos);
                    } else switch (listLike.def) {
                        case EBlock(_):
                            // Wrap block receiver as IIFE to make it a valid expression
                            var iife2 = makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: listLike }])), "", []));
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "join", [iife2, sep1]), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function tryRewriteJoinArgBlock(block: ElixirAST): Null<ElixirAST> {
        // Unwrap IIFE that returns a block list-builder: (fn -> <block> end).()
        var candidate: ElixirAST = switch (block.def) {
            case ECall({def: EFn(fns)}, _, _) if (fns.length == 1):
                var body = fns[0].body;
                switch (body.def) { case EBlock(_): body; default: block; }
            default: block;
        };
        return switch (candidate.def) {
            case EBlock(stmts) if (stmts.length >= 3):
                var temp: Null<String> = null;           // initializer var from []
                var builderVar: Null<String> = null;      // actual mutated accumulator var
                var listExpr: Null<ElixirAST> = null;
                var binder: String = "item";
                var valueExpr: Null<ElixirAST> = null;
                var inlineVar: Null<String> = null;
                var inlineExpr: Null<ElixirAST> = null;
                // 1) temp = []
                switch (stmts[0].def) {
                    case EBinary(Match, {def: EVar(tn)}, {def: EList([])}): temp = tn;
                    case EMatch(PVar(tn2), {def: EList([])}): temp = tn2;
                    default: return null;
                }
                // 2) Enum.each(list, fn binder -> temp = Enum.concat(temp, [value]) end)
                var eachIdx = -1;
                for (i in 1...stmts.length - 1) {
                    switch (stmts[i].def) {
                        case ERemoteCall({def: EVar("Enum")}, "each", eargs) if (eargs != null && eargs.length == 2):
                            listExpr = eargs[0];
                            switch (eargs[1].def) {
                                case EFn(clauses) if (clauses.length == 1):
                                    var cl = clauses[0];
                                    switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): binder = n; default: }
                                var bodyStmts: Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                                for (bs in bodyStmts) {
                                    switch (bs.def) {
                                        // Detect inline temporary assignment like: i = binder + 1
                                        case EBinary(Match, {def: EVar(lhsTmp)}, rhsTmp):
                                            switch (rhsTmp.def) {
                                                case EBinary(Add, {def: EVar(bv)}, _incrRhs) if (bv == binder):
                                                    inlineVar = lhsTmp; inlineExpr = rhsTmp;
                                                case ERemoteCall({def: EVar("Enum")}, "concat", cargs2) if (cargs2.length == 2):
                                                    // Also discover builderVar from concat(update) even when lhs != temp
                                                    switch (cargs2[0].def) {
                                                        case EVar(vacc) if (vacc == lhsTmp): builderVar = lhsTmp;
                                                        default:
                                                    }
                                                default:
                                            }
                                        case EBinary(Match, {def: EVar(lhs)}, rhs):
                                            switch (rhs.def) {
                                                case ERemoteCall({def: EVar("Enum")}, "concat", cargs) if (cargs.length == 2):
                                                    // Accept either temp or discovered builderVar as concat base
                                                    var baseOk = switch (cargs[0].def) {
                                                        case EVar(v) if (v == (builderVar != null ? builderVar : temp)): true;
                                                        default: false;
                                                    };
                                                    if (baseOk) {
                                                        switch (cargs[1].def) {
                                                            case EList(items) if (items.length == 1):
                                                                valueExpr = items[0];
                                                            default:
                                                        }
                                                        if (builderVar == null) switch (cargs[0].def) {
                                                            case EVar(vb): builderVar = vb;
                                                            default:
                                                        }
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                }
                                default:
                            }
                            eachIdx = i;
                        default:
                    }
                }
                if (listExpr == null || valueExpr == null || eachIdx == -1) return null;
                // 3) If valueExpr references inlineVar, substitute it with inlineExpr
                if (valueExpr != null && inlineVar != null && inlineExpr != null) {
                    valueExpr = substituteVar(valueExpr, inlineVar, inlineExpr);
                }
                // 4) Final statement returns accumulator (temp or builderVar)
                var last = stmts[stmts.length - 1];
                var accName = (builderVar != null ? builderVar : temp);
                var returnsAcc = switch (last.def) { case EVar(nm) if (nm == accName): true; default: false; };
                if (!returnsAcc) return null;
                // Build Enum.map(list, fn binder -> valueExpr end)
                var fnNode = makeAST(EFn([{ args: [PVar(binder)], guard: null, body: valueExpr }]));
                makeAST(ERemoteCall(makeAST(EVar("Enum")), "map", [listExpr, fnNode]));
            default:
                null;
        }
    }

    static function substituteVar(ast: ElixirAST, varName: String, replacement: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == varName): replacement;
                default: n;
            }
        });
    }
}

#end
