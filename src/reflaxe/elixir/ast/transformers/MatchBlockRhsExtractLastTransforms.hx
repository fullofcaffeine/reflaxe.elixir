package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MatchBlockRhsExtractLastTransforms
 *
 * WHAT
 * - In statement-list contexts, rewrite match assignments whose RHS is a block so that the
 *   match binds to the block's final expression, while preserving all preceding statements.
 *
 * WHY
 * - Haxe inlining and assignment extraction can produce shapes like:
 *     varName = (stmt1; stmt2; expr)
 *   If we later flatten that block without care, we can accidentally bind `varName` to
 *   `stmt1` (or discard `expr`), changing semantics and dropping required values.
 *
 * HOW
 * - For each statement in an `EBlock`/`EDo` list:
 *   - If the statement is `pat = <block>` (or `left = <block>`), expand it into:
 *       <block prefix statements...>
 *       pat = <block last expression>
 *   - This is only applied where we are already in a statement list, so the expansion
 *     remains valid Elixir without needing parenthesized expression blocks.
 *
 * EXAMPLES
 * Elixir AST (before):
 *   slug = do
 *     s = String.downcase(text)
 *     StringTools.trim(s)
 *   end
 * Elixir AST (after):
 *   s = String.downcase(text)
 *   slug = StringTools.trim(s)
 */
class MatchBlockRhsExtractLastTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
                case EDo(stmts2):
                    makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    private static function rewrite(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length == 0) return stmts;
        var out: Array<ElixirAST> = [];
        for (s in stmts) {
            var expanded = expandStatement(s);
            if (expanded != null) {
                for (e in expanded) out.push(e);
            } else {
                out.push(s);
            }
        }
        return out;
    }

    private static function expandStatement(stmt: ElixirAST): Null<Array<ElixirAST>> {
        if (stmt == null || stmt.def == null) return null;

        // Match form: pat = <block>
        switch (stmt.def) {
            case EMatch(pat, rhs):
                var blockStmts = extractBlockStatements(rhs);
                if (blockStmts == null) return null;
                return expandMatchLike(stmt, function(lastExpr) {
                    return makeASTWithMeta(EMatch(pat, lastExpr), stmt.metadata, stmt.pos);
                }, blockStmts);

            // Binary match form: left = <block>
            case EBinary(Match, left, rhs2):
                var blockStmts2 = extractBlockStatements(rhs2);
                if (blockStmts2 == null) return null;
                return expandMatchLike(stmt, function(lastExpr2) {
                    return makeASTWithMeta(EBinary(Match, left, lastExpr2), stmt.metadata, stmt.pos);
                }, blockStmts2);

            default:
                return null;
        }
    }

    private static function extractBlockStatements(rhs: ElixirAST): Null<Array<ElixirAST>> {
        if (rhs == null || rhs.def == null) return null;
        return switch (rhs.def) {
            case EBlock(inner): inner;
            case EDo(inner2): inner2;
            case EParen(inner3): extractBlockStatements(inner3);
            default: null;
        }
    }

    private static function expandMatchLike(
        template: ElixirAST,
        rebuild: ElixirAST -> ElixirAST,
        innerStatements: Array<ElixirAST>
    ): Array<ElixirAST> {
        var result: Array<ElixirAST> = [];
        if (innerStatements == null || innerStatements.length == 0) {
            result.push(rebuild(makeAST(ENil)));
            return result;
        }

        // Choose the last non-empty expression as the value.
        // Some transformations may leave trailing empty blocks (EBlock([])/EDo([])) or nulls,
        // which would print as nothing and produce invalid `var =` lines.
        var lastIndex = innerStatements.length - 1;
        while (lastIndex >= 0 && isEmptyExpr(innerStatements[lastIndex])) {
            lastIndex--;
        }
        if (lastIndex < 0) {
            result.push(rebuild(makeAST(ENil)));
            return result;
        }

        // Prefix statements keep their own metadata; drop trailing empties.
        for (i in 0...lastIndex) {
            if (!isEmptyExpr(innerStatements[i])) result.push(innerStatements[i]);
        }

        var lastExpr = innerStatements[lastIndex];
        result.push(rebuild(lastExpr));
        return result;
    }

    private static function isEmptyExpr(expr: Null<ElixirAST>): Bool {
        if (expr == null || expr.def == null) return true;
        return switch (expr.def) {
            case EBlock(stmts): stmts == null || stmts.length == 0;
            case EDo(stmts2): stmts2 == null || stmts2.length == 0;
            default: false;
        }
    }
}

#end
