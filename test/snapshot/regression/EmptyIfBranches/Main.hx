/**
 * Regression test for Bug #1: Empty if-expression generates invalid Elixir syntax
 *
 * Bug Description:
 * The printer was generating `if c == nil, do: , else:` (invalid) instead of using
 * block syntax with 'nil' for empty branches.
 *
 * Root Cause:
 * isSimpleExpression() at line 1368 of ElixirASTPrinter.hx incorrectly returned true
 * for EBlock([]), causing inline syntax to be used even when branches are empty.
 *
 * Fix:
 * Modified isSimpleExpression() to return false for empty blocks, forcing block syntax.
 */
class Main {
    /**
     * Test 1: Empty then branch with non-empty else
     * Should generate block syntax, not inline
     */
    static function testEmptyThen(c: Null<Int>): String {
        if (c == null) {
            // Empty then branch
        } else {
            return "not null";
        }
        return "after if";
    }

    /**
     * Test 2: Non-empty then with empty else
     * Should generate block syntax, not inline
     */
    static function testEmptyElse(c: Null<Int>): String {
        if (c != null) {
            return "not null";
        } else {
            // Empty else branch
        }
        return "after if";
    }

    /**
     * Test 3: Both branches empty
     * Should generate block syntax with nil for both branches
     */
    static function testBothEmpty(c: Bool): Void {
        if (c) {
            // Empty if
        } else {
            // Empty else
        }
    }

    /**
     * Test 4: Nested empty if expressions
     * Tests multiple levels of empty branches
     */
    static function testNestedEmpty(a: Bool, b: Bool): Void {
        if (a) {
            if (b) {
                // Nested empty
            } else {
                // Nested empty
            }
        } else {
            // Empty outer else
        }
    }

    /**
     * Test 5: The original JsonPrinter pattern
     * This is the exact pattern that caused the bug
     */
    static function testJsonPrinterPattern(charCode: Int): String {
        var result = "";

        if (charCode < 0x20) {
            // Empty - this was generating invalid syntax
        } else {
            result = String.fromCharCode(charCode);
        }

        return result;
    }

    public static function main() {
        trace(testEmptyThen(null));
        trace(testEmptyElse(42));
        testBothEmpty(true);
        testNestedEmpty(true, false);
        trace(testJsonPrinterPattern(65));
    }
}
