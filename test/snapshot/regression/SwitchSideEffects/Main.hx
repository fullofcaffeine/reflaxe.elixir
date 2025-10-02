/**
 * Regression test for Bug #2: Switch case branches with side-effects disappear
 *
 * Root Cause:
 * SwitchBuilder.hx line 222 silently replaces NULL with ENil when case body
 * compilation fails, hiding the real bug in compound assignment handling.
 *
 * This test reproduces the exact pattern from JsonPrinter.hx lines 127-143
 * where switch cases with compound assignments should generate rebinding
 * patterns but instead disappear.
 */
class Main {
    /**
     * Test case: Switch with compound assignments (+=) INSIDE A LOOP
     * This is the EXACT pattern from JsonPrinter.quoteString() method
     * that triggers Bug #2 where cases disappear.
     */
    static function testSwitchInsideLoop(input: String): String {
        var result = "";

        // THE CRITICAL PATTERN: Switch inside a for loop
        for (i in 0...input.length) {
            var charCode = input.charCodeAt(i);

            switch (charCode) {
                case 0x22: result += '\\"';   // Compound assignment inside loop
                case 0x5C: result += '\\\\';
                case 0x08: result += '\\b';
                case 0x0C: result += '\\f';
                case 0x0A: result += '\\n';
                case 0x0D: result += '\\r';
                case 0x09: result += '\\t';
                default:
                    if (charCode < 0x20) {
                        result += '\\u0000';
                    } else {
                        result += input.charAt(i);
                    }
            }
        }

        return result;
    }

    /**
     * Control test: Switch with compound assignments (NO loop)
     * This should work correctly as we saw in previous compilation.
     */
    static function testSwitchWithoutLoop(charCode: Int): String {
        var result = "";

        switch (charCode) {
            case 0x22: result += '\\"';   // Compound assignment
            case 0x5C: result += '\\\\';
            case 0x08: result += '\\b';
            default: result += "other";
        }

        return result;
    }

    /**
     * Test case: Switch with simple assignments (no +=)
     * This should work correctly as a control
     */
    static function testSwitchWithSimpleAssignment(charCode: Int): String {
        var result = "";

        switch (charCode) {
            case 0x22: result = '\\"';    // Simple assignment
            case 0x5C: result = '\\\\';
            default: result = "other";
        }

        return result;
    }

    /**
     * Test case: Switch with mixed operations (+=, -=, *=)
     * Tests multiple compound assignment operators
     */
    static function testMixedOperations(code: Int): Int {
        var counter = 10;

        switch (code) {
            case 1: counter += 5;     // Add
            case 2: counter -= 3;     // Subtract
            case 3: counter *= 2;     // Multiply
            default: counter = 0;     // Reset
        }

        return counter;
    }

    /**
     * Test case: Nested switch with side effects
     * Tests compound assignments in nested switch statements
     */
    static function testNestedSwitch(outer: Int, inner: Int): String {
        var result = "";

        switch (outer) {
            case 1:
                switch (inner) {
                    case 1: result += "1-1";
                    case 2: result += "1-2";
                    default: result += "1-?";
                }
            case 2:
                switch (inner) {
                    case 1: result += "2-1";
                    case 2: result += "2-2";
                    default: result += "2-?";
                }
            default:
                result += "?-?";
        }

        return result;
    }

    public static function main() {
        // Test 1: CRITICAL PATTERN - switch inside loop (exposes Bug #2)
        trace(testSwitchInsideLoop('test"\\'));

        // Test 2: Control - switch without loop (should work)
        trace(testSwitchWithoutLoop(0x22));

        // Test 3: Control - simple assignments (should work)
        trace(testSwitchWithSimpleAssignment(0x22));

        // Test 4: Mixed operations (+=, -=, *=)
        trace(testMixedOperations(1));  // Should be 15
        trace(testMixedOperations(2));  // Should be 7
        trace(testMixedOperations(3));  // Should be 20

        // Test 5: Nested switch with compound assignments
        trace(testNestedSwitch(1, 1));  // Should be "1-1"
        trace(testNestedSwitch(2, 2));  // Should be "2-2"
        trace(testNestedSwitch(9, 9));  // Should be "?-?"
    }
}
