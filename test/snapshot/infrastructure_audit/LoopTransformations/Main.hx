/**
 * Infrastructure Audit: Loop Transformation Passes
 *
 * Tests whether the loop transformation infrastructure (LoopBuilder, LoopTransformationPass)
 * correctly transforms loops to idiomatic Elixir patterns now that the flag bug is fixed.
 *
 * Expected Behavior (after flag fix):
 * - Simple for loops → Enum.each
 * - Array building loops → Comprehensions or Enum.map
 * - Conditional loops → Enum.filter or comprehensions with guards
 * - NO reduce_while patterns for simple cases
 */
class Main {
    static function main() {
        // Test 1: Simple range iteration (should become Enum.each)
        for (i in 0...5) {
            trace('Index: $i');
        }

        // Test 2: Array iteration (should become Enum.each)
        var fruits = ["apple", "banana", "cherry"];
        for (fruit in fruits) {
            trace('Fruit: $fruit');
        }

        // Test 3: Array comprehension - building array (should become comprehension or Enum.map)
        var doubled = [for (n in [1, 2, 3, 4, 5]) n * 2];
        trace(doubled);

        // Test 4: Filtered comprehension (should become comprehension with guard)
        var evens = [for (n in [1, 2, 3, 4, 5, 6]) if (n % 2 == 0) n];
        trace(evens);

        // Test 5: Nested loops (should become nested comprehension)
        var grid = [for (i in 0...3) [for (j in 0...3) i * 3 + j]];
        trace(grid);
    }
}
