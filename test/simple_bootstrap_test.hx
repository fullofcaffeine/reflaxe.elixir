class SimpleBootstrapTest {
    static function main() {
        // Simple test that doesn't require complex dependencies
        var numbers = [1, 2, 3, 4, 5];
        
        // Test map operation
        var doubled = numbers.map(x -> x * 2);
        trace("Doubled: " + doubled);
        
        // Test filter operation  
        var evens = numbers.filter(x -> x % 2 == 0);
        trace("Evens: " + evens);
        
        // Test concatenation
        var more = numbers.concat([6, 7, 8]);
        trace("Concatenated: " + more);
        
        trace("Bootstrap test complete!");
    }
}