/**
 * Test source map generation infrastructure
 * 
 * This test verifies that source maps are generated (even if currently empty)
 * and will validate proper mappings once the feature is complete.
 */
class Main {
    static function main() {
        // Simple function to test source mapping
        var result = add(1, 2);
        trace("Result: " + result);
        
        // Test with different expression types
        testConditional();
        testLoop();
        testLambda();
    }
    
    static function add(a: Int, b: Int): Int {
        // This should generate a mapping from Elixir line to this Haxe line
        return a + b;
    }
    
    static function testConditional(): Void {
        var x = 10;
        if (x > 5) {
            trace("Greater than 5");
        } else {
            trace("Less than or equal to 5");
        }
    }
    
    static function testLoop(): Void {
        var items = [1, 2, 3, 4, 5];
        for (item in items) {
            trace("Item: " + item);
        }
    }
    
    static function testLambda(): Void {
        var numbers = [1, 2, 3];
        var doubled = numbers.map(function(n) {
            return n * 2;
        });
        trace("Doubled: " + doubled);
    }
}