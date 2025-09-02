/**
 * Test for proper statement separation in generated Elixir code.
 * 
 * This tests that multiple statements are properly separated with newlines,
 * especially when dealing with complex assignment expressions.
 */
class Main {
    static function testComplexAssignment() {
        var i = 0;
        var index;
        var c;
        
        // Multiple assignments in sequence (should be on separate lines)
        c = index = i + 1;
        var result = someFunction(index);
        
        // Complex expression with bit operations
        c = c - 55232 << 10 | (index = i + 1);
        var masked = someFunction(index) & 1023;
        
        trace("c: " + c + ", masked: " + masked);
    }
    
    static function someFunction(x: Int): Int {
        return x * 2;
    }
    
    static function main() {
        testComplexAssignment();
    }
}