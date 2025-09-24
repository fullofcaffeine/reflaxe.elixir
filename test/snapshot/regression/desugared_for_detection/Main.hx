/**
 * Regression test for desugared for loop detection
 * 
 * Verifies that simple for loops generate idiomatic Elixir (Enum.each)
 * instead of verbose reduce_while patterns.
 */
class Main {
    static function main() {
        // Simple for loop with side effects
        // Should generate: Enum.each(0..4, fn i -> Log.trace(...) end)
        for (i in 0...5) {
            trace('Iteration $i');
        }
        
        // Nested loops
        // Should generate nested Enum.each calls
        for (x in 0...3) {
            for (y in 0...3) {
                trace('Position: ($x, $y)');
            }
        }
    }
}