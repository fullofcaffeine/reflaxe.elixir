using ArrayTools;
using MapTools;

/**
 * MapTools functional methods test case
 * Tests MapTools static extension methods for proper compilation to idiomatic Elixir
 */
class Main {
    static function main() {
        var numbers = ["one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5];
        
        // Test size method - compiles to Map.size
        var count = numbers.size();
        trace('Map size: $count');
        
        // Test isEmpty method
        var notEmpty = numbers.isEmpty();
        trace('Numbers empty check: $notEmpty');
        
        // Test isEmpty on empty map
        var empty = new Map<String, Int>();
        var isEmptyResult = empty.isEmpty();
        trace('Empty map check: $isEmptyResult');
        
        // Test any method - should compile to Enum.any?
        var hasEven = numbers.any((k, v) -> v % 2 == 0);
        trace('Has even values: $hasEven');
        
        // Test all method - should compile to Enum.all?
        var allPositive = numbers.all((k, v) -> v > 0);
        trace('All positive: $allPositive');
        
        // Test reduce method - should compile to Map.fold or Enum.reduce
        var sum = numbers.reduce(0, (acc, k, v) -> acc + v);
        trace('Sum of values: $sum');
        
        // Test find method - should return proper tuple structure
        var found = numbers.find((k, v) -> v > 3);
        if (found != null) {
            trace('Found item with value > 3: ${found.key} = ${found.value}');
        }
        
        // Test keys method (returns Array) - use explicit call to avoid confusion with Map.keys()
        var keyArray = MapTools.keys(numbers);
        trace('Keys array length: ${keyArray.length}');
        
        // Test values method (returns Array) - use explicit call
        var valueArray = MapTools.values(numbers);
        trace('Values array length: ${valueArray.length}');
        
        // Test toArray method (returns Array) - use explicit call
        var pairArray = MapTools.toArray(numbers);
        trace('Pairs array length: ${pairArray.length}');
    }
}