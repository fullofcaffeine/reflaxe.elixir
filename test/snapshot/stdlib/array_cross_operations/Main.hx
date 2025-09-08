/**
 * Test Array.cross.hx inline methods with __elixir__ injection
 * Verifies that array operations generate idiomatic Elixir code
 */
class Main {
    static function main() {
        testBasicOperations();
        testChaining();
        testListOperations();
    }
    
    static function testBasicOperations() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Test map - should generate Enum.map
        var doubled = numbers.map(x -> x * 2);
        trace("Doubled: " + doubled);
        
        // Test filter - should generate Enum.filter
        var evens = numbers.filter(x -> isEven(x));
        trace("Evens: " + evens);
        
        // Test concat - should generate ++
        var more = numbers.concat([6, 7, 8]);
        trace("Concatenated: " + more);
    }
    
    static function testChaining() {
        var data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        // Chain filter and map - should generate nested Enum calls
        var result = data
            .filter(x -> x > 5)
            .map(x -> x * 10)
            .filter(x -> x < 100);
        trace("Chained result: " + result);
        
        // Multiple maps
        var transformed = data
            .map(x -> x + 1)
            .map(x -> x * 2)
            .map(x -> x - 3);
        trace("Triple mapped: " + transformed);
    }
    
    static function testListOperations() {
        var items = ["apple", "banana", "cherry", "date"];
        
        // Simple indexOf without fromIndex
        var cherryIndex = items.indexOf("cherry");
        trace("Index of cherry: " + cherryIndex);
        
        // List operations
        var list = [1, 2, 3];
        
        // push - should generate list ++ [item]
        list.push(4);
        trace("After push: " + list);
        
        // concat arrays
        var combined = list.concat([5, 6, 7]);
        trace("Combined: " + combined);
        
        // Check contains using indexOf
        var hasTwo = list.indexOf(2) != -1;
        trace("Has 2: " + hasTwo);
    }
    
    // Helper to avoid modulo operator issue
    static function isEven(n: Int): Bool {
        return n % 2 == 0;
    }
}