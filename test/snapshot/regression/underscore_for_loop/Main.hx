/**
 * Regression Test: Underscore variables in for loops
 * 
 * This test ensures that underscore variables (_) in for loops are properly
 * converted and tracked through the compilation pipeline.
 * 
 * Bug History:
 * - The compiler was converting _ to "item" in the pattern but not tracking
 *   the renaming for TLocal references in the body
 * - Fixed by registering variable renaming in TFor case of ElixirASTBuilder
 * 
 * Related commits: Fix underscore variable handling in TFor loops
 */
class Main {
    public static function main() {
        // Test 1: Simple underscore in for loop
        var count = 0;
        for (_ in [1, 2, 3]) {
            count++;
        }
        trace('Count: $count');
        
        // Test 2: Lambda with underscore variable
        var numbers = [1, 2, 3, 4, 5];
        var total = Lambda.count(numbers);
        trace('Total count: $total');
        
        // Test 3: Empty check with underscore
        var emptyList: Array<Int> = [];
        var nonEmptyList = [1];
        trace('Empty list is empty: ${Lambda.empty(emptyList)}');
        trace('Non-empty list is empty: ${Lambda.empty(nonEmptyList)}');
        
        // Test 4: Nested for loops with underscores
        var matrix = [[1, 2], [3, 4], [5, 6]];
        var rows = 0;
        for (_ in matrix) {
            rows++;
            var cols = 0;
            for (_ in [1, 2]) {
                cols++;
            }
            trace('Columns: $cols');
        }
        trace('Rows: $rows');
    }
}