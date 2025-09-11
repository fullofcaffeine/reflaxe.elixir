/**
 * Regression test for conditional array comprehension compilation
 * 
 * ISSUE: Conditional array comprehensions were generating invalid Elixir code
 * - Extra parentheses around filter expressions caused syntax errors
 * - Detection pattern was looking at wrong nesting level in TBlock
 * - Erlang remote calls had double colon prefix (::erlang instead of :erlang)
 * 
 * FIXED: Now generates idiomatic Elixir for comprehensions with filters
 * 
 * @see https://github.com/EliteMasterEric/reflaxe.Elixir/commit/75d6d44c
 */
class Main {
    static function main() {
        // Simple conditional comprehension
        var evens = [for (i in 0...10) if (i % 2 == 0) i];
        trace('Even numbers: $evens'); // Should be [0, 2, 4, 6, 8]
        
        // Conditional comprehension with expression
        var evenSquares = [for (i in 1...10) if (i % 2 == 0) i * i];
        trace('Even squares: $evenSquares'); // Should be [4, 16, 36, 64]
        
        // Note: Multiple conditions currently fall back to imperative code
        // This is a known limitation - single conditions work perfectly
        
        // Conditional comprehension with complex expression
        var results = [for (x in 1...5) if (x > 2) {value: x, square: x * x}];
        trace('Results: $results'); // Objects with value and square for x > 2
        
        // Ensure proper filter syntax without extra parentheses
        var odds = [for (n in 0...10) if (n % 2 != 0) n];
        trace('Odd numbers: $odds'); // Should be [1, 3, 5, 7, 9]
    }
}