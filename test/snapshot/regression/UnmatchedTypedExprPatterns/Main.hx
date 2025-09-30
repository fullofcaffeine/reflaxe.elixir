/**
 * Regression Test: Unmatched TypedExpr Patterns
 *
 * BUG HISTORY:
 * - Issue: Compiler failed with "Unmatched patterns: TCast | TMeta | TParenthesis | TTypeExpr"
 * - Root Cause: ElixirASTBuilder.hx switch statement (line 481) missing handlers for 4 TypedExpr patterns
 * - Impact: ALL tests blocked - compiler couldn't process these common expression types
 * - Date Fixed: 2025-01-29
 * - Fix: Added inline case handlers for all 4 patterns following established codebase patterns
 *
 * This test ensures these patterns continue to compile correctly.
 */
class Main {
    static function main() {
        trace("Testing unmatched TypedExpr patterns...");

        // TMeta test - Metadata annotations (compile-time only)
        @:meta("test_annotation") var x = 1;
        trace("TMeta: x = " + x);

        // TParenthesis test - Parenthesized expressions for grouping
        var y = (x + 1) * 2;
        trace("TParenthesis: y = " + y);

        // TCast test - Type casts (transparent in Elixir)
        var z: Any = 42;
        var num = cast(z, Int);
        trace("TCast: num = " + num);

        // TTypeExpr test - Type/module references
        var typeName = Type.getClassName(Main);
        trace("TTypeExpr: typeName = " + typeName);

        trace("All patterns compiled successfully!");
    }
}