using MapTools;

/**
 * Simplified MapTools test focusing on non-Map-creating methods first
 */
class MainSimple {
    
    static function basicOperations() {
        var numbers = ["one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5];
        
        // Test size - should compile to Map.size
        var count = numbers.size();
        trace('Map size: $count');
        
        // Test isEmpty on non-empty map
        var notEmpty = numbers.isEmpty();
        trace('Numbers empty check: $notEmpty');
        
        // Test isEmpty on empty map
        var empty = new Map<String, Int>();
        var isEmptyResult = empty.isEmpty();
        trace('Empty map check: $isEmptyResult');
        
        // Test any - should compile to proper Elixir predicate
        var hasEven = numbers.any((k, v) -> v % 2 == 0);
        trace('Has even values: $hasEven');
        
        // Test all - should compile to proper Elixir predicate  
        var allPositive = numbers.all((k, v) -> v > 0);
        trace('All positive: $allPositive');
        
        // Test reduce - should compile to Map.fold
        var sum = numbers.reduce(0, (acc, k, v) -> acc + v);
        trace('Sum of values: $sum');
        
        // Test find - should return proper tuple structure
        var found = numbers.find((k, v) -> v > 3);
        if (found != null) {
            trace('Found item with value > 3: ${found.key} = ${found.value}');
        }
    }
    
    static function main() {
        trace("=== Simple MapTools Test ===");
        basicOperations();
        trace("=== Test Complete ===");
    }
}