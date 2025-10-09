package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WHAT
 * ReduceWhileInitCleanup: De-infrastructure the initial accumulator passed to Enum.reduce_while.
 * - Inlines alias locals used solely to build the accumulator init.
 * - Folds pure alias assignments into accumulator tuples and removes the dead assignments.
 *
 * WHY
 * Haxe desugaring and prior extraction passes may introduce alias locals (g/_g/gN or other
 * temporaries) before Enum.reduce_while. When the accumulator initialization is built from
 * these aliases, infra variables leak into the final AST or create unnecessary assignments.
 * We want clean, idiomatic code: pass the RHS directly as the accumulator init and remove
 * dead, side-effect-free alias statements.
 *
 * HOW (High-level)
 * - Walk blocks (EBlock) and detect patterns around an ERemoteCall(Enum, "reduce_while", ...).
 * - If the 2nd arg (initAcc) is a plain variable bound immediately before by a pure assignment,
 *   inline the RHS into the reduce_while call and drop the assignment.
 * - If the 2nd arg is a tuple containing variables bound immediately before by pure assignments,
 *   inline each pure RHS into the tuple and drop the corresponding assignments when safe.
 * - Side-effect analysis is conservative: only inline literals, tuples/lists/maps/keywords/structs,
 *   variables, and parentheses. Function/remote calls are considered effectful and not inlined.
 *
 * CONTEXT
 * - Builder → Transformer → Printer pipeline.
 * - This is a transformer fallback. The preferred solution is builder-side inlining in LoopBuilder
 *   when constructing reduce_while; this pass cleans residual cases produced by other builders
 *   and extraction passes.
 *
 * EDGE CASES / GUARDRAILS
 * - Do not inline through effectful expressions (function/remote calls, raises, etc.).
 * - Only elide assignments when we can prove a single, immediate use feeding initAcc.
 * - Preserve metadata and positions for stable diffs and diagnostics.
 *
 * EXAMPLES
 * Before (statement context):
 *   acc0 = {map, count}
 *   Enum.reduce_while(iter, acc0, fn _, {map, count} -> ... end)
 * After:
 *   Enum.reduce_while(iter, {map, count}, fn _, {map, count} -> ... end)
 *
 * Before (tuple components):
 *   m = %{}
 *   c = 0
 *   Enum.reduce_while(iter, {m, c}, fun)
 * After:
 *   Enum.reduce_while(iter, {%{}, 0}, fun)
 */
class ReduceWhileInitCleanup {
    public static function reduceWhileInitCleanupPass(ast: ElixirAST): ElixirAST {
        function isPure(e: ElixirAST): Bool {
            return switch (e.def) {
                case EVar(_): true;
                case EAtom(_): true;
                case EString(_): true;
                case EInteger(_): true;
                case EFloat(_): true;
                case EBoolean(_): true;
                case ENil: true;
                case ECharlist(_): true;
                case EParen(inner): isPure(inner);
                case ETuple(items):
                    var ok = true; for (i in items) if (!isPure(i)) { ok = false; break; } ok;
                case EList(items):
                    var ok = true; for (i in items) if (!isPure(i)) { ok = false; break; } ok;
                case EMap(pairs):
                    var ok = true; for (p in pairs) if (!isPure(p.value)) { ok = false; break; } ok;
                case EKeywordList(pairs):
                    var ok = true; for (p in pairs) if (!isPure(p.value)) { ok = false; break; } ok;
                case EStruct(_, fields):
                    var ok = true; for (f in fields) if (!isPure(f.value)) { ok = false; break; } ok;
                default: false;
            };
        }

        // Attempt to inline a single alias assignment immediately preceding idx
        function inlineSingleAlias(stmts: Array<ElixirAST>, idx: Int, accVar: String): {inlined: ElixirAST, removed: Bool} {
            if (idx <= 0) return {inlined: null, removed: false};
            switch (stmts[idx - 1].def) {
                case EMatch(PVar(v), rhs) if (v == accVar && isPure(rhs)):
                    return {inlined: rhs, removed: true};
                default:
            }
            return {inlined: null, removed: false};
        }

        // Attempt to inline tuple component aliases immediately preceding idx
        function inlineTupleAliases(stmts: Array<ElixirAST>, idx: Int, tuple: Array<ElixirAST>): {inlined: Array<ElixirAST>, removedFlags: Array<Bool>} {
            var out:Array<ElixirAST> = [];
            var removed:Array<Bool> = [];
            for (el in tuple) {
                switch (el.def) {
                    case EVar(name):
                        var res = inlineSingleAlias(stmts, idx, name);
                        if (res.inlined != null) {
                            out.push(res.inlined);
                            removed.push(res.removed);
                        } else {
                            out.push(el);
                            removed.push(false);
                        }
                    default:
                        out.push(el);
                        removed.push(false);
                }
            }
            return {inlined: out, removedFlags: removed};
        }

        function processBlock(block: ElixirAST): ElixirAST {
            return switch (block.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case ERemoteCall(mod, fname, args):
                                var isEnum = switch (mod.def) { case EVar(mn): mn == "Enum"; default: false; };
                                if (isEnum && fname == "reduce_while" && args != null && args.length >= 3) {
                                    var iter = args[0];
                                    var accInit = args[1];
                                    var fun = args[2];
                                    var removedPrev = false;
                                    var newAcc:ElixirAST = accInit;
                                    switch (accInit.def) {
                                        case EVar(accName):
                                            var r = inlineSingleAlias(stmts, i, accName);
                                            if (r.inlined != null) { newAcc = r.inlined; removedPrev = r.removed; }
                                        case ETuple(items):
                                            var r2 = inlineTupleAliases(stmts, i, items);
                                            if (r2.inlined != null) {
                                                newAcc = makeAST(ETuple(r2.inlined));
                                                var allPrev = true;
                                                for (f in r2.removedFlags) if (!f) { allPrev = false; break; }
                                                if (allPrev) removedPrev = true;
                                            }
                                        default:
                                    }
                                    if (removedPrev) {
                                        if (out.length > 0) out.pop();
                                    }
                                    out.push(makeAST(ERemoteCall(mod, fname, [iter, newAcc, fun])));
                                } else {
                                    out.push(ElixirASTTransformer.transformAST(s, processBlock));
                                }
                            default:
                                out.push(ElixirASTTransformer.transformAST(s, processBlock));
                        }
                        i++;
                    }
                    makeAST(EBlock(out));
                default:
                    ElixirASTTransformer.transformAST(block, processBlock);
            };
        }

        return processBlock(ast);
    }
}

#end
