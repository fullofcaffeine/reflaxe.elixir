package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * SwitchResultInlineReturnFixTransforms
 *
 * WHAT
 * - Fixes shapes where a function/block ends with `switch_result_N` but the
 *   binding assignment was eliminated, leaving an undefined variable in return
 *   position. Moves the corresponding `case` expression to the end so it
 *   becomes the returned value.
 *
 * WHY
 * - Case/switch lowering may introduce a temp (e.g., `__elixir_switch_result_4`)
 *   that later gets renamed to `switch_result_4`. Late hygiene or folds can
 *   eliminate the binding while leaving the trailing reference. Returning an
 *   undefined variable causes a compile error.
 *
 * HOW
 * - For EDef/EDefp bodies that are EBlock([... , EVar("switch_result_*")]):
 *   - Find the last ECase within the same block.
 *   - Remove that ECase from its position and replace the trailing var with it.
 *   - This preserves evaluation order for preceding statements and ensures the
 *     function returns the case expression result.
 */
class SwitchResultInlineReturnFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, fixBlock(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, fixBlock(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixBlock(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts) if (stmts != null && stmts.length >= 2):
                var last = stmts[stmts.length - 1];
                var trailingName: Null<String> = switch (last.def) { case EVar(v): v; default: null; };
                if (trailingName == null || !StringTools.startsWith(trailingName, "switch_result_")) return body;

                // Build index map for assignments `switch_result_* = case ... end`
                var assignIndex = -1;
                var caseExpr: ElixirAST = null;
                for (i in 0...stmts.length - 1) {
                    switch (stmts[i].def) {
                        case EMatch(pat, rhs):
                            var name: Null<String> = switch (pat) { case PVar(n): n; default: null; };
                            if (name != null && name == trailingName) switch (rhs.def) {
                                case ECase(_, _): assignIndex = i; caseExpr = rhs;
                                default:
                            }
                        case EBinary(Match, left, rhs2):
                            var name2: Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                            if (name2 != null && name2 == trailingName) switch (rhs2.def) {
                                case ECase(_, _): assignIndex = i; caseExpr = rhs2;
                                default:
                            }
                        default:
                    }
                }

                if (assignIndex == -1 || caseExpr == null) {
                    // fallback: move last case in block if exists
                    var lastCaseIndex = -1;
                    for (i in 0...stmts.length - 1) switch (stmts[i].def) { case ECase(_, _): lastCaseIndex = i; default: }
                    if (lastCaseIndex == -1) return body;
                    var out1 = [];
                    for (i in 0...stmts.length - 1) if (i != lastCaseIndex) out1.push(stmts[i]);
                    out1.push(stmts[lastCaseIndex]);
                    return makeASTWithMeta(EBlock(out1), body.metadata, body.pos);
                }

                // Rewrite: drop the assignment stmt and replace trailing var with the case expr
                var out = [];
                for (i in 0...stmts.length - 1) if (i != assignIndex) out.push(stmts[i]);
                out.push(caseExpr);
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }
}

#end
