// Comprehensive Loop Pattern Test Suite
// Tests all loop patterns to ensure robust transformation to idiomatic Elixir

class Main {
    public static function main() {
        // Test 1: Simple for loop with side effects only
        trace("=== Test 1: Simple Loop ===");
        for (i in 0...5) {
            trace("Index: " + i);
        }
        
        // Test 2: Loop with arithmetic expressions
        trace("=== Test 2: Arithmetic Expressions ===");
        for (i in 0...4) {
            trace("Double: " + (i * 2));
            trace("Square: " + (i * i));
            trace("Plus offset: " + (i + 10));
        }
        
        // Test 3: Loop with complex expressions
        trace("=== Test 3: Complex Expressions ===");
        for (n in 0...3) {
            var result = n * 3 + 5;
            trace("n * 3 + 5 = " + result);
            trace("Expression inline: " + (n * 2 + 1));
        }
        
        // Test 4: Nested loops
        trace("=== Test 4: Nested Loops ===");
        for (i in 0...2) {
            for (j in 0...3) {
                trace("Position (" + i + ", " + j + ")");
            }
        }
        
        // Test 5: Nested loops with expressions
        trace("=== Test 5: Nested with Expressions ===");
        for (x in 0...2) {
            for (y in 0...2) {
                trace("Grid[" + (x * 10) + "][" + (y * 10) + "]");
            }
        }
        
        // Test 6: Loop with function calls
        trace("=== Test 6: Function Calls ===");
        for (i in 0...3) {
            trace("Doubled: " + double(i));
            trace("Squared: " + square(i));
        }
        
        // Test 7: Edge case - empty loop (0 iterations)
        trace("=== Test 7: Empty Loop ===");
        for (i in 0...0) {
            trace("This should not print");
        }
        
        // Test 8: Edge case - single iteration
        trace("=== Test 8: Single Iteration ===");
        for (i in 0...1) {
            trace("Single: " + i);
        }
        
        // Test 9: Loop with array building (collecting results)
        trace("=== Test 9: Array Building ===");
        var evens = [];
        for (i in 0...10) {
            if (i % 2 == 0) {
                evens.push(i);
            }
        }
        trace("Evens: " + evens);
        
        // Test 10: Loop with break
        trace("=== Test 10: Loop with Break ===");
        for (i in 0...10) {
            if (i == 5) {
                trace("Breaking at 5");
                break;
            }
            trace("Count: " + i);
        }
        
        // Test 11: Loop with continue
        trace("=== Test 11: Loop with Continue ===");
        for (i in 0...5) {
            if (i == 2) {
                trace("Skipping 2");
                continue;
            }
            trace("Value: " + i);
        }
        
        // Test 12: Bracket notation pattern (simulated)
        trace("=== Test 12: Bracket Notation ===");
        var grid = [[1, 2], [3, 4]];
        for (i in 0...2) {
            for (j in 0...2) {
                trace("grid[" + i + "][" + j + "] = " + grid[i][j]);
            }
        }
        
        // Test 13: Triple nested loops (stress test)
        trace("=== Test 13: Triple Nested ===");
        for (i in 0...2) {
            for (j in 0...2) {
                for (k in 0...2) {
                    trace("3D: (" + i + "," + j + "," + k + ")");
                }
            }
        }
        
        // Test 14: Loop variable shadowing
        trace("=== Test 14: Variable Shadowing ===");
        var i = 100;
        for (i in 0...3) {
            trace("Inner i: " + i);
        }
        trace("Outer i: " + i); // Should still be 100
        
        // Test 15: While loop equivalent
        trace("=== Test 15: While Loop Pattern ===");
        var count = 0;
        while (count < 3) {
            trace("While count: " + count);
            count++;
        }
    }
    
    static function double(n: Int): Int {
        return n * 2;
    }
    
    static function square(n: Int): Int {
        return n * n;
    }
}