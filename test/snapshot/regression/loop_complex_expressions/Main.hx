// Test: Complex expressions in loops should be preserved during transformation
// This test verifies that arithmetic expressions and function calls in loop bodies
// are maintained when converting to Elixir's Enum.each pattern

class Main {
    public static function main() {
        // Test 1: Simple arithmetic expression
        trace("Test 1: Arithmetic expressions");
        for (i in 0...5) {
            trace("Value: " + (i * 2 + 1));
        }
        
        // Test 2: More complex expression with offset
        trace("Test 2: Expression with offset");
        var offset = 10;
        for (n in 0...4) {
            trace("Result: " + (n + offset));
        }
        
        // Test 3: Nested arithmetic in unrolled loop
        trace("Test 3: Nested loop with expressions");
        for (i in 0...2) {
            for (j in 0...2) {
                trace("Grid[" + (i * 3) + "][" + (j * 2) + "]");
            }
        }
        
        // Test 4: Function call in loop expression
        trace("Test 4: Function call expression");
        for (x in 0...3) {
            trace("Square: " + square(x));
        }
        
        // Test 5: Multiple complex expressions
        trace("Test 5: Multiple expressions");
        for (k in 0...3) {
            trace("k*2=" + (k * 2) + ", k^2=" + (k * k) + ", k+5=" + (k + 5));
        }
    }
    
    static function square(n: Int): Int {
        return n * n;
    }
}