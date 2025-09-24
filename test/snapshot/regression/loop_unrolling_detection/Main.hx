package;

/**
 * Test for detecting and transforming unrolled loops back to idiomatic Elixir
 * 
 * Haxe's optimizer unrolls small constant loops before they reach our compiler.
 * This test validates that we can detect such patterns and transform them to Enum.each
 */
class Main {
    static function main() {
        // This loop should be unrolled by Haxe's optimizer
        // and then detected and transformed back by our compiler
        for (i in 0...3) {
            haxe.Log.trace('Iteration ' + i, null);
        }
        
        // Test with slightly different pattern
        for (j in 0...4) {
            trace('Value: ' + j);
        }
        
        // Nested loop should not be unrolled (too complex)
        for (x in 0...2) {
            for (y in 0...2) {
                trace('Pair: ' + x + ', ' + y);
            }
        }
    }
}