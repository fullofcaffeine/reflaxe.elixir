package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListHelpersFixTransforms
 *
 * WHAT
 * - A bundle of small, shape-only fixes for common list helper patterns:
 *   1) containsToEnumMemberPass: Rewrite arr.contains(v) -> Enum.member?(arr, v).
 *   2) memberFilterRemovalFixPass: In `if Enum.member?(list, val) do Enum.filter(list, fn x -> x != x end) end`,
 *      replace the self-compare with `x != val`.
 *   3) filterReturnInlineFixPass: When a filter result is computed under an if but the function returns
 *      the original list variable, rewrite to inline if returning the filtered list.
 *   4) handleInfoTupleArgToSecondElemPass: In `case msg do {:tag, v} -> remove_*_from_list(msg, socket) end`,
 *      pass `v` instead of `msg` for list helper calls (remove_*_from_list / update_*_in_list).
 *
 * WHY
 * - These patterns are target-idiomatic and arise from neutral lowering; the fixes make the behavior
 *   correct without app-specific names.
 */
class ListHelpersFixTransforms {
    // 1) arr.contains(v) -> Enum.member?(arr, v)
    public static function containsToEnumMemberPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case ECall(target, "contains", [arg]) if (target != null):
                    return makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "member?", [target, arg]), n.metadata, n.pos);
                default:
                    return n;
            }
        });
    }

    // 2) If cond uses Enum.member?(list, val) then filter(list, fn x -> x != x end) -> x != val
    public static function memberFilterRemovalFixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenB, elseB):
                    // Extract list and value from member?
                    var listExpr: ElixirAST = null;
                    var valExpr: ElixirAST = null;
                    switch (cond.def) {
                        case ERemoteCall({def: EVar(m)}, "member?", [l, v]) if (m == "Enum"): listExpr = l; valExpr = v;
                        default:
                    }
                    if (listExpr == null || valExpr == null) return n;
                    var fixedThen = ElixirASTTransformer.transformNode(thenB, function(x: ElixirAST): ElixirAST {
                        switch (x.def) {
                            case ERemoteCall({def: EVar(m2)}, "filter", [l2, fnNode]) if (m2 == "Enum"):
                                switch (fnNode.def) {
                                    case EFn(clauses) if (clauses.length == 1):
                                        var cl = clauses[0];
                                        var binder: Null<String> = switch (cl.args.length == 1 ? cl.args[0] : null) { case PVar(nm): nm; default: null; };
                                        if (binder == null) return x;
                                        switch (cl.body.def) {
                                            case EBinary(NotEqual | StrictNotEqual, l3, r3):
                                                inline function isBinder(e: ElixirAST): Bool return switch (e.def) { case EVar(nm) if (nm == binder): true; default: false; };
                                                if (isBinder(l3) && isBinder(r3)) {
                                                    var newBody = makeAST(EBinary(NotEqual, l3, valExpr));
                                                    var newFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]));
                                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "filter", [l2, newFn]), x.metadata, x.pos);
                                                } else return x;
                                            default: return x;
                                        }
                                    default: return x;
                                }
                            default: return x;
                        }
                    });
                    // Replace the EIf node with an inline if that returns the (potentially fixed) then-branch
                    return makeASTWithMeta(EIf(cond, fixedThen, listExpr), n.metadata, n.pos);
                default:
                    return n;
            }
        });
    }

    // 3) Inline return of filter result when last expression returns original list
    public static function filterReturnInlineFixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefp(name, args, guards, body) | EDef(name, args, guards, body):
                    var newBody = body;
                    switch (body.def) {
                        case EBlock(stmts) if (stmts.length >= 2):
                            var last = stmts[stmts.length - 1];
                            var retVar: Null<String> = switch (last.def) { case EVar(v): v; default: null; };
                            if (retVar == null) return n;
                            // Look for trailing if that computes filter on same retVar but discards result
                            for (i in 0...stmts.length - 1) {
                                switch (stmts[i].def) {
                                    case EIf(cond, thenB, els):
                                        // Collect the first Enum.filter on the return var inside the then block
                                        var filterExpr: ElixirAST = null;
                                        ElixirASTTransformer.transformNode(thenB, function(z: ElixirAST): ElixirAST {
                                            switch (z.def) {
                                                case ERemoteCall({def: EVar("Enum")}, "filter", [lX, _]) if (switch (lX.def) { case EVar(vx) if (vx == retVar): true; default: false; }):
                                                    if (filterExpr == null) filterExpr = z;
                                                    return z;
                                                default: return z;
                                            }
                                        });
                                        if (filterExpr == null) continue;
                                        // Replace the last return with inline if
                                        var out:Array<ElixirAST> = [];
                                        for (j in 0...stmts.length - 1) if (j != i) out.push(stmts[j]);
                                        out.push(makeAST(EIf(cond, filterExpr, makeAST(EVar(retVar)))));
                                        newBody = makeAST(EBlock(out));
                                    default:
                                }
                            }
                        default:
                    }
                    if (newBody == body) n else makeASTWithMeta(Type.enumConstructor(n.def) == "EDef" ? EDef(name, args, guards, newBody) : EDefp(name, args, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // 4) In case msg of {:tag, v}, replace helper call arg `msg` -> `v` for *_from_list/*_in_list helpers
    public static function handleInfoTupleArgToSecondElemPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses):
                    var scrut: Null<String> = switch (expr.def) { case EVar(v): v; default: null; };
                    if (scrut == null) return n;
                    var newClauses:Array<ECaseClause> = [];
                    for (cl in clauses) {
                        var idVar: Null<String> = null;
                        switch (cl.pattern) {
                            case PTuple([PLiteral(_), PVar(v)]): idVar = v;
                            default:
                        }
                        if (idVar == null) { newClauses.push(cl); continue; }
                        var newBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                            switch (x.def) {
                                case ECall(t, fname, args) if (args != null && args.length >= 1 && scrut != null && fname != null && (StringTools.endsWith(fname, "_from_list") || StringTools.endsWith(fname, "_in_list"))):
                                    var newArgs = args.copy();
                                    if (switch (newArgs[0].def) { case EVar(v0) if (v0 == scrut): true; default: false; }) newArgs[0] = makeAST(EVar(idVar));
                                    return makeASTWithMeta(ECall(t, fname, newArgs), x.metadata, x.pos);
                                case ERemoteCall(m, fname2, args2) if (args2 != null && args2.length >= 1 && scrut != null && fname2 != null && (StringTools.endsWith(fname2, "_from_list") || StringTools.endsWith(fname2, "_in_list"))):
                                    var newArgs2 = args2.copy();
                                    if (switch (newArgs2[0].def) { case EVar(v1) if (v1 == scrut): true; default: false; }) newArgs2[0] = makeAST(EVar(idVar));
                                    return makeASTWithMeta(ERemoteCall(m, fname2, newArgs2), x.metadata, x.pos);
                                default:
                                    return x;
                            }
                        });
                        newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
