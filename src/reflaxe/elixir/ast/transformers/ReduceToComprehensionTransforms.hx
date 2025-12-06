package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceToComprehensionTransforms
 *
 * WHAT
 * - Rewrites Enum.reduce(range, [], fn iter, acc -> Enum.concat(acc, [value]) end)
 *   into an idiomatic Elixir list comprehension:
 *     for iter <- range, do: value
 * - Also handles reducer bodies that rebind the accumulator and then return it:
 *     acc = Enum.concat(acc, [value]); acc
 *
 * WHY
 * - The builder lowers list-producing for-loops into reduce in some cases.
 *   For canonical “append single element per iteration” patterns, comprehensions
 *   are the idiomatic representation and avoid invalid intermediate list-building
 *   fragments in nested scenarios.
 *
 * HOW
 * - Detects ERemoteCall(Enum, "reduce", [source, [], fn ... -> body end])
 * - Extracts the last accumulator update to `Enum.concat(acc, [value])` or
 *   `acc ++ [value]` and rewrites the whole call to EFor(generator, filters=[], value).
 * - Conservative: Only fires when the initial accumulator is an empty list and
 *   the reducer has exactly two params (iter, acc). Does not tie to app code.
 */
class ReduceToComprehensionTransforms {
    public static function rewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar(mod)}, "reduce", args) if (mod == "Enum" && args != null && args.length >= 3):
                    // DEBUG: opportunistic trace to confirm detection (will be removed once stable)
                    var source = args[0];
                    var init = args[1];
                    var reducer = args[2];
                    // Initial accumulator must be an empty list
                    var emptyInit = switch (init.def) { case EList(elements) if (elements.length == 0): true; default: false; };
                    if (!emptyInit) {
                        n;
                    } else switch (reducer.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var cl = clauses[0];
                            // Expect two-arg reducer: fn iter, acc -> ... end
                            var iterName: Null<String> = null;
                            var accName: Null<String> = null;
                            switch (cl.args) {
                                case [PVar(a), PVar(b)]:
                                    iterName = a; accName = b;
                                case _:
                                    iterName = null; accName = null;
                            }
                            if (iterName == null || accName == null) {
                                n;
                            } else {
                                var valueExpr: Null<ElixirAST> = extractAppendedElement(cl.body, iterName, accName);
                                if (valueExpr == null || isEmptyValue(valueExpr)) {
                                    n; // Not a canonical append-single-element reducer
                                } else {
                                    // Build comprehension: for <iter> <- <source>, do: <valueExpr>
                                    // If source is Map.values(coll), unwrap to coll to avoid
                                    // invalid generators like `for x <- Map.values(0..2)`.
                                    var unwrappedSource: ElixirAST = switch (source.def) {
                                        case ERemoteCall({def: EVar(mapMod)}, "values", [inner]) if (mapMod == "Map"): inner;
                                        default: source;
                                    };
                                    // Wrap in parentheses to avoid ambiguity inside containers (lists/maps)
                                    var gen = { pattern: PVar(iterName), expr: unwrappedSource };
                                    var comp = makeAST(EFor([gen], [], valueExpr, null, false));
                                    makeASTWithMeta(EParen(comp), n.metadata, n.pos);
                                }
                            }
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static inline function isEmptyValue(e: ElixirAST): Bool {
        return switch (e.def) {
            case ENil: true;
            case EBlock(sts) if (sts == null || sts.length == 0): true;
            default: false;
        };
    }

    /**
     * Extract the appended single element `[value]` from a reducer body that
     * updates `acc` by appending a single element and then returns the accumulator.
     */
    static function extractAppendedElement(body: ElixirAST, iterName: String, accName: String): Null<ElixirAST> {
        // Look for the last effective assignment to `acc` in the body
        // Accept both direct return of concat(acc, [v]) and rebinding followed by acc
        return switch (body.def) {
            case EBlock(stmts) if (stmts.length > 0):
                // Find the last assignment to acc
                var lastValue: Null<ElixirAST> = null;
                for (s in stmts) switch (s.def) {
                    case EBinary(EBinaryOp.Match, {def: EVar(lhs)}, rhs) if (lhs == accName):
                        // acc = rhs
                        var v = extractFromConcat(rhs, accName);
                        if (v != null) lastValue = v;
                    case _:
                }
                if (lastValue != null) lastValue else {
                    // Fallback: if the block’s final expression is concat(acc, [v]), use it
                    var last = stmts[stmts.length - 1];
                    var fromConcat = extractFromConcat(last, accName);
                    if (fromConcat != null) fromConcat else extractFromPushPattern(stmts, iterName, accName);
                }
            case _:
                var fromConcatTop = extractFromConcat(body, accName);
                if (fromConcatTop != null) fromConcatTop else null;
        }
    }

    /**
     * Extract `[value]` from `Enum.concat(acc, [value])` or `acc ++ [value]` shapes.
     */
    static function extractFromConcat(expr: ElixirAST, accName: String): Null<ElixirAST> {
        return switch (expr.def) {
            case ERemoteCall({def: EVar(mod)}, "concat", cargs) if (mod == "Enum" && cargs != null && cargs.length == 2):
                switch (cargs[0].def) {
                    case EVar(v) if (v == accName):
                        switch (cargs[1].def) {
                            case EList(listElts) if (listElts.length == 1): listElts[0];
                            default: null;
                        }
                    default: null;
                }
            case EBinary(EBinaryOp.Add, {def: EVar(v)}, rhs) if (v == accName):
                switch (rhs.def) {
                    case EList(listElts2) if (listElts2.length == 1): listElts2[0];
                    default: null;
                }
            default:
                null;
        }
    }

    /**
     * Extract `[value]` from a reducer block that uses a sentinel `push(value)`
     * call followed by returning `acc`. This covers builder-emitted shapes
     * before concat/++ lowering.
     */
    static function extractFromPushPattern(stmts: Array<ElixirAST>, iterName: String, accName: String): Null<ElixirAST> {
        var pushed: Null<ElixirAST> = null;
        var returnsAcc = false;
        for (s in stmts) switch (s.def) {
            case ECall(func, method, args):
                // Match bare push(value) — module is null and method == "push"
                var isBarePushWithArg = (func == null && method == "push" && args != null && args.length >= 1);
                var isBarePushNoArg = (func == null && method == "push" && (args == null || args.length == 0));
                if (isBarePushWithArg && pushed == null) {
                    pushed = args[0];
                } else if (isBarePushNoArg && pushed == null) {
                    // Zero-arg push sentinel: assume canonical append of current iterator
                    // This occurs in lowered patterns where the yield value is the binder.
                    pushed = makeAST(EVar(iterName));
                }
            case EVar(name) if (name == accName):
                returnsAcc = true; // final return acc
            default:
        }
        return (pushed != null && returnsAcc) ? pushed : null;
    }
}

#end
