/**
 * Regression test for Do-While Loop Compound Assignment Bug
 *
 * Bug Description:
 * Do-while loops with compound string assignments generate EMPTY loop bodies,
 * causing undefined variable errors at runtime.
 *
 * Example from StringTools.hex:
 * do {
 *     s = hexChars.charAt(n & 15) + s;  // Compound assignment
 *     n >>>= 4;
 * } while (n > 0);
 *
 * Generated: Enum.reduce_while(..., fn _, {n, s} ->  end)  // EMPTY BODY!
 * Result: Undefined variable 'g' error
 *
 * Root Cause:
 * LoopBuilder doesn't preserve loop bodies when compound assignments exist.
 * The transformation from `s = expr + s` to `s = expr <> s` happens,
 * but the body gets lost in the pipeline.
 *
 * Fix Required:
 * Proper pipeline coordination between LoopBuilder and compound assignment handling.
 * Should generate recursive function with rebinding pattern.
 */
class Main {
    /**
     * Test 1: Basic do-while with string compound assignment
     * This is the exact pattern from StringTools.hex that fails
     */
    static function testBasicDoWhile(): String {
        var s = "";
        var n = 255;
        do {
            s = "x" + s;  // Compound assignment - prepend
            n--;
        } while (n > 0);
        return s;
    }

    /**
     * Test 2: Do-while with multiple compound operations
     * Tests that complex bodies are preserved
     */
    static function testMultipleOperations(): String {
        var s = "";
        var n = 5;
        do {
            s = String.fromCharCode(65 + n) + s;
            n--;
        } while (n >= 0);
        return s;
    }

    /**
     * Test 3: Do-while with numeric compound assignment
     * Ensures the bug isn't specific to strings
     */
    static function testNumericCompound(): Int {
        var sum = 0;
        var i = 5;
        do {
            sum += i;
            i--;
        } while (i > 0);
        return sum;
    }

    /**
     * Test 4: Nested do-while loops
     * Tests that both inner and outer loops preserve bodies
     */
    static function testNestedDoWhile(): String {
        var result = "";
        var i = 2;
        do {
            var j = 2;
            do {
                result = "." + result;
                j--;
            } while (j > 0);
            i--;
        } while (i > 0);
        return result;
    }

    public static function main() {
        trace(testBasicDoWhile());
        trace(testMultipleOperations());
        trace(testNumericCompound());
        trace(testNestedDoWhile());
    }
}
