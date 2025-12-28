package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EarlyReturnIfElseTransforms
 *
 * WHAT
 * - Rewrites statement-level early returns compiled as `if cond, do: <expr>` into a proper
 *   `if ... else ... end` expression by moving the remainder of the surrounding block into
 *   the else branch.
 *
 * WHY
 * - Haxe allows early returns (`if (cond) return x; ...`), but Elixir has no `return` keyword.
 * - When `return` is lowered to just its expression, the naive translation becomes:
 *     if cond, do: x
 *     rest()
 *   which changes semantics (rest executes even when Haxe returned).
 *
 * HOW
 * - The builder tags nodes originating from `TReturn` using `metadata.fromReturn`.
 * - This pass scans EBlock/EDo sequences for:
 *     EIf(cond, thenBranch(fromReturn), elseBranch = null)
 *   and, when there are subsequent statements, rewrites to:
 *     EIf(cond, thenBranch, elseBranch = <rest-of-block>)
 *   recursively applying the same rewrite within the else branch.
 *
 * EXAMPLES
 * Haxe:
 *   if (todo == null) return socket;
 *   return recomputeVisible(socket);
 * Elixir (before):
 *   if Kernel.is_nil(todo), do: socket
 *   recompute_visible(socket)
 * Elixir (after):
 *   if Kernel.is_nil(todo) do
 *     socket
 *   else
 *     recompute_visible(socket)
 *   end
 */
class EarlyReturnIfElseTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    rewriteSequenceAsSameKind(stmts, function(exprs) return makeASTWithMeta(EBlock(exprs), node.metadata, node.pos));
                case EDo(stmts):
                    rewriteSequenceAsSameKind(stmts, function(exprs) return makeASTWithMeta(EDo(exprs), node.metadata, node.pos));
                default:
                    node;
            }
        });
    }

    static inline function isFromReturn(n: ElixirAST): Bool {
        if (n == null) return false;
        if (n.metadata != null && n.metadata.fromReturn == true) return true;
        return switch (n.def) {
            case EBlock(stmts) | EDo(stmts):
                stmts != null && stmts.length > 0 && isFromReturn(stmts[stmts.length - 1]);
            case EParen(inner):
                isFromReturn(inner);
            default:
                false;
        };
    }

    static function rewriteSequenceAsSameKind(stmts: Array<ElixirAST>, wrap: Array<ElixirAST> -> ElixirAST): ElixirAST {
        if (stmts == null || stmts.length == 0) return wrap([]);

        var out: Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
            var stmt = stmts[i];

            switch (stmt.def) {
                case EIf(condition, thenBranch, null) if (isFromReturn(thenBranch) && i < stmts.length - 1):
                    var rest = stmts.slice(i + 1);
                    var elseExpr = buildRestExpr(rest, stmt.metadata, stmt.pos);
                    out.push(makeASTWithMeta(EIf(condition, thenBranch, elseExpr), stmt.metadata, stmt.pos));
                    return wrap(out);

                case EUnless(condition, body, null) if (isFromReturn(body) && i < stmts.length - 1):
                    var restUnless = stmts.slice(i + 1);
                    var elseExprUnless = buildRestExpr(restUnless, stmt.metadata, stmt.pos);
                    out.push(makeASTWithMeta(EUnless(condition, body, elseExprUnless), stmt.metadata, stmt.pos));
                    return wrap(out);

                default:
                    out.push(stmt);
                    i++;
            }
        }

        return wrap(out);
    }

    static function buildRestExpr(rest: Array<ElixirAST>, meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        // Recursively rewrite early-return patterns within the remainder.
        var rewritten = rewriteSequenceAsSameKind(rest, function(exprs) return makeASTWithMeta(EBlock(exprs), meta, pos));
        return switch (rewritten.def) {
            case EBlock(exprs) if (exprs != null && exprs.length == 1):
                // Prefer a single expression over a 1-element block in branches.
                exprs[0];
            default:
                rewritten;
        };
    }
}

#end
