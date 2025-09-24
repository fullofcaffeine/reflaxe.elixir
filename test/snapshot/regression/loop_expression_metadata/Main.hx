// Test: Loop expression metadata preservation
// This test verifies that expressions like "i * 2 + 1" are preserved as metadata
// instead of being evaluated to constants at compile-time

class Main {
    public static function main() {
        // Simple arithmetic expression in loop
        trace("Test 1: Arithmetic in loop");
        for (i in 0...3) {
            trace(i * 2 + 1);
        }
        
        // More complex expression
        trace("Test 2: Complex expression");
        for (j in 0...2) {
            trace((j + 5) * 3);
        }
        
        // Expression with variable reference
        trace("Test 3: Expression with offset");
        var offset = 10;
        for (k in 0...2) {
            trace(k + offset);
        }
    }
}