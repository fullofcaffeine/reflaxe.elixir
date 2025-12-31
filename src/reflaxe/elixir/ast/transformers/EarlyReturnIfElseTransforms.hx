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
 *     EIf(cond, thenBranch(contains fromReturn), elseBranch = null)
 *   and, when there are subsequent statements:
 *   1) Moves the remainder of the sequence into the else branch
 *   2) If the then-branch only *contains* an early return (nested), appends the remainder
 *      to the then-branch too so fallthrough paths continue correctly.
 *   3) Recursively rewrites early-return patterns inside the inserted remainder.
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

    static function containsFromReturn(n: ElixirAST): Bool {
        if (n == null || n.def == null) return false;

        var found = false;

        function scan(node: ElixirAST): Void {
            if (found || node == null || node.def == null) return;
            if (node.metadata != null && node.metadata.fromReturn == true) {
                found = true;
                return;
            }
            ElixirASTTransformer.iterateAST(node, scan);
        }

        scan(n);
        return found;
    }

    static function appendContinuation(branch: ElixirAST, continuation: ElixirAST): ElixirAST {
        if (branch == null || branch.def == null) return branch;
        if (continuation == null || continuation.def == null) return branch;

        return switch (branch.def) {
            case EBlock(stmts):
                var combined = (stmts != null ? stmts : []).concat([continuation]);
                rewriteSequenceAsSameKind(combined, function(exprs) return makeASTWithMeta(EBlock(exprs), branch.metadata, branch.pos));

            case EDo(stmts):
                var combined = (stmts != null ? stmts : []).concat([continuation]);
                rewriteSequenceAsSameKind(combined, function(exprs) return makeASTWithMeta(EDo(exprs), branch.metadata, branch.pos));

            case EParen(inner):
                makeASTWithMeta(EParen(appendContinuation(inner, continuation)), branch.metadata, branch.pos);

            default:
                var combined = [branch, continuation];
                var rewritten = rewriteSequenceAsSameKind(combined, function(exprs) return makeASTWithMeta(EBlock(exprs), branch.metadata, branch.pos));
                switch (rewritten.def) {
                    case EBlock(exprs) if (exprs != null && exprs.length == 1):
                        exprs[0];
                    default:
                        rewritten;
                }
        };
    }

    static function rewriteSequenceAsSameKind(stmts: Array<ElixirAST>, wrap: Array<ElixirAST> -> ElixirAST): ElixirAST {
        if (stmts == null || stmts.length == 0) return wrap([]);

        var out: Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
            var stmt = stmts[i];

            switch (stmt.def) {
                case EIf(condition, thenBranch, null) if (containsFromReturn(thenBranch) && i < stmts.length - 1):
                    var rest = stmts.slice(i + 1);
                    var elseExpr = buildRestExpr(rest, stmt.metadata, stmt.pos);
                    var thenWithContinuation = isFromReturn(thenBranch) ? thenBranch : appendContinuation(thenBranch, elseExpr);
                    out.push(makeASTWithMeta(EIf(condition, thenWithContinuation, elseExpr), stmt.metadata, stmt.pos));
                    return wrap(out);

                case EUnless(condition, body, null) if (containsFromReturn(body) && i < stmts.length - 1):
                    var restUnless = stmts.slice(i + 1);
                    var elseExprUnless = buildRestExpr(restUnless, stmt.metadata, stmt.pos);
                    var bodyWithContinuation = isFromReturn(body) ? body : appendContinuation(body, elseExprUnless);
                    out.push(makeASTWithMeta(EUnless(condition, bodyWithContinuation, elseExprUnless), stmt.metadata, stmt.pos));
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
