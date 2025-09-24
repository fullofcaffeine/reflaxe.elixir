package;

/**
 * Edge case tests for loop unrolling detection
 * Testing various patterns to ensure robustness
 */
class Main {
    static function main() {
        // Test 1: Simple incrementing loop (should be detected)
        for (i in 0...3) {
            trace('Step ' + i);
        }
        
        // Test 2: Non-sequential indices (should NOT be detected)
        trace('Random 0');
        trace('Random 5');  // Gap in sequence
        trace('Random 1');
        
        // Test 3: Mixed patterns in same block (should detect first group)
        for (j in 0...3) {
            haxe.Log.trace('Loop A: ' + j, null);
        }
        someOtherFunction();
        for (k in 0...2) {
            haxe.Log.trace('Loop B: ' + k, null);
        }
        
        // Test 4: Different function calls (should be separate groups)
        for (x in 0...2) {
            trace('First: ' + x);
        }
        for (y in 0...2) {
            haxe.Log.trace('Second: ' + y, null);
        }
        
        // Test 5: Single iteration (should NOT be detected as loop)
        for (z in 0...1) {
            trace('Single: ' + z);
        }
        
        // Test 6: Large loop (likely won't be unrolled by Haxe)
        for (big in 0...100) {
            trace('Big: ' + big);
        }
        
        // Test 7: String interpolation patterns
        for (m in 0...3) {
            trace('Item $m of total');
        }
        
        // Test 8: Complex expression in trace
        for (n in 0...3) {
            trace('Result: ' + (n * 2));
        }
    }
    
    static function someOtherFunction() {
        trace("Breaking the pattern");
    }
}