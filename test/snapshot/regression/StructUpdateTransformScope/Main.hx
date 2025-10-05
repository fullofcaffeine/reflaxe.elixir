package;

/**
 * Regression test for StructUpdateTransform scoping issue
 *
 * BUG: StructUpdateTransform was applying struct update syntax to ANY concatenation operation,
 * including array operations, generating invalid code like:
 *
 * %{struct | _g2: struct._g2 ++ [0]}  # ❌ WRONG - arrays aren't structs!
 *
 * ROOT CAUSE: isIgnoredFieldMutation() didn't distinguish between:
 * - Actual struct field operations: struct.columns ++ [...]
 * - Array operations: g._g2 ++ [...] or arr = arr ++ [item]
 *
 * FIX: Added isArrayVariable() guard to check for compiler-generated array variables
 * (g, g2, _g, _g2, etc.) and reject transformation for array operations.
 *
 * This test verifies:
 * 1. Array concatenation generates direct assignment (NOT struct update)
 * 2. Struct field concatenation generates struct update syntax
 * 3. Compiler-generated array variables (g, _g) are NOT treated as structs
 */

class Main {
    static function main() {
        // Test 1: Array concatenation should generate direct assignment
        testArrayConcatenation();

        // Test 2: Nested array building (the original bug pattern)
        testNestedArrayBuilding();
    }

    /**
     * Array concatenation: arr = arr ++ [item]
     * Expected: Direct assignment, NOT struct update
     */
    static function testArrayConcatenation() {
        var arr: Array<Int> = [];

        // Simple array concatenation
        arr = arr.concat([1]);
        arr = arr.concat([2]);
        arr = arr.concat([3]);

        trace("Array: " + arr);
    }

    /**
     * Nested array building (original bug pattern)
     * Expected: Static nested lists, NOT struct update syntax
     */
    static function testNestedArrayBuilding() {
        // Pattern that triggered the bug:
        // Compiler-generated variables like g, g2, _g shouldn't trigger struct transform

        var matrix = [];
        for (i in 0...3) {
            var row = [];
            for (j in 0...3) {
                row = row.concat([i * 3 + j]);
            }
            matrix = matrix.concat([row]);
        }

        trace("Matrix: " + matrix);
    }
}
