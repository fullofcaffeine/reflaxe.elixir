package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterPredicateNormalizeTransforms
 *
 * WHAT
 * - Ensures all `Enum.filter/2` calls use a structured anonymous function (`EFn`) as
 *   the predicate. Normalizes predicates appearing in direct calls, method-style
 *   calls (list.filter), and in RHS of assignments. Avoids generating ERaw content.
 *
 * WHY
 * - Downstream passes (query binding/inlining, binder hygiene, warnings cleanup)
 *   assume the predicate is an `EFn` with a single element binder. When predicates
 *   arrive as non-`EFn` expressions or captures, later transforms become brittle,
 *   leading to undefined variables (e.g., `query`) and non-deterministic rewrites.
 *
 * HOW
 * - For `Enum.filter(list, pred)` where `pred` is not `EFn`:
 *   - Wrap in `EFn([{ args: [PVar("elem")], guard: null, body: pred' }])`
 *   - If `pred` is a capture or function variable, call it with the binder using
 *     `ECall(target=captureOrVar, funcName="", args=[EVar("elem")])` so it prints as `f.(elem)`.
 *   - If `pred` is already an `EFn`, leave unchanged.
 * - Handles shapes:
 *   - `ERemoteCall(EVar("Enum"), "filter", [list, pred])`
 *   - `ECall(list, "filter", [pred])` (method-style lowered later by printer)
 *   - The above inside `EMatch` RHS.
 *
 * EXAMPLES
 * Haxe:
 *   todos.filter(t -> String.contains(t.title, query))
 * Elixir (before):
 *   Enum.filter(todos, String.contains?(t.title, query))
 * Elixir (after):
 *   Enum.filter(todos, fn elem -> String.contains?(elem.title, query) end)
 */
class FilterPredicateNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Direct Enum.filter(list, pred)
                case ERemoteCall({def: EVar(mod)}, "filter", args) if (mod == "Enum" && args != null && args.length == 2):
                    var normalized = ensureFnPredicate(args[0], args[1], n.metadata, n.pos);
                    if (normalized == null) n else
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "filter", [normalized.list, normalized.predicate]), n.metadata, n.pos);

                // Method-style list.filter(pred) (rewritten to Enum by printer)
                case ECall(target, "filter", args2) if (args2 != null && args2.length == 1):
                    var normalized2 = ensureFnPredicate(target, args2[0], n.metadata, n.pos);
                    if (normalized2 == null) n else
                        makeASTWithMeta(ECall(normalized2.list, "filter", [normalized2.predicate]), n.metadata, n.pos);

                // Matches where RHS is a filter call
                case EMatch(pat, rhs):
                    switch (rhs.def) {
                        case ERemoteCall({def: EVar(mod2)}, "filter", a3) if (mod2 == "Enum" && a3 != null && a3.length == 2):
                            var normalized3 = ensureFnPredicate(a3[0], a3[1], rhs.metadata, rhs.pos);
                            if (normalized3 == null) n else {
                                var repl = makeAST(ERemoteCall(makeAST(EVar("Enum")), "filter", [normalized3.list, normalized3.predicate]));
                                makeASTWithMeta(EMatch(pat, repl), n.metadata, n.pos);
                            }
                        case ECall(t2, "filter", a4) if (a4 != null && a4.length == 1):
                            var normalized4 = ensureFnPredicate(t2, a4[0], rhs.metadata, rhs.pos);
                            if (normalized4 == null) n else {
                                var repl2 = makeAST(ECall(normalized4.list, "filter", [normalized4.predicate]));
                                makeASTWithMeta(EMatch(pat, repl2), n.metadata, n.pos);
                            }
                        default:
                            n;
                    }

                default:
                    n;
            }
        });
    }

    static function ensureFnPredicate(listExpr: ElixirAST, pred: ElixirAST, meta: Dynamic, pos: Dynamic): Null<{ list: ElixirAST, predicate: ElixirAST }>{
        if (pred == null || pred.def == null) return null;
        return switch (pred.def) {
            case EFn(_):
                // Already normalized
                { list: listExpr, predicate: pred };

            case ECapture(_,_):
                // Wrap capture in a closure that calls it: fn elem -> (&cap).(elem) end
                var binder = makeAST(EVar("elem"));
                var call = makeAST(ECall(pred, "", [binder]));
                var fnNode = makeAST(EFn([{ args: [PVar("elem")], guard: null, body: call }]));
                #if debug_filter_predicate
                // DISABLED: trace('[FilterPredNorm] Wrapped ECapture into EFn predicate');
                #end
                { list: listExpr, predicate: fnNode };

            case EVar(_) | EField(_, _):
                // Function variable or field holding a function: call with elem
                var binder2 = makeAST(EVar("elem"));
                var call2 = makeAST(ECall(pred, "", [binder2]));
                var fnNode2 = makeAST(EFn([{ args: [PVar("elem")], guard: null, body: call2 }]));
                #if debug_filter_predicate
                // DISABLED: trace('[FilterPredNorm] Wrapped function variable into EFn predicate');
                #end
                { list: listExpr, predicate: fnNode2 };

            default:
                // Generic expression: wrap directly as body. We do not synthesize ERaw.
                // Downstream passes may further rewrite body and binder usage.
                var fnNode3 = makeAST(EFn([{ args: [PVar("elem")], guard: null, body: pred }]));
                #if debug_filter_predicate
                // DISABLED: trace('[FilterPredNorm] Normalized non-EFn predicate of type ' + Type.enumConstructor(pred.def));
                #end
                { list: listExpr, predicate: fnNode3 };
        }
    }
}

#end

