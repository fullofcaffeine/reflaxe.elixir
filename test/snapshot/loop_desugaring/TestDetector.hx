/**
 * Test harness for DesugarredForDetector
 * 
 * This test verifies that the detector correctly identifies
 * desugared for loop patterns in TBlock expressions.
 */
class TestDetector {
    static function main() {
        // Test pattern 1: Simple for(i in 0...5)
        // Desugared to: var g = 0; var g1 = 5; while(g < g1) { var i = g; g++; ... }
        testSimpleFor();
        
        // Test pattern 2: With _g prefix
        // Desugared to: var _g = 0; var _g1 = 10; while(_g < _g1) { ... }
        testUnderscorePrefix();
        
        // Test pattern 3: Nested loops with numeric suffixes
        // Outer: g, g1  Inner: g2, g3
        testNestedLoops();
    }
    
    static function testSimpleFor(): Void {
        // This will be desugared by Haxe
        for (i in 0...5) {
            trace('Iteration $i');
        }
    }
    
    static function testUnderscorePrefix(): Void {
        // This will use _g variables
        var result = 0;
        for (j in 0...10) {
            result += j;
        }
        trace('Sum: $result');
    }
    
    static function testNestedLoops(): Void {
        // Nested loops use different numeric suffixes
        for (x in 0...3) {
            for (y in 0...3) {
                trace('($x, $y)');
            }
        }
    }
}