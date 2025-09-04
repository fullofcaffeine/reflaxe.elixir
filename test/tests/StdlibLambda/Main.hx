package;

/**
 * Test Lambda standard library implementation
 * 
 * Validates that Lambda correctly uses the Elixir Enum extern
 * and generates idiomatic Elixir functional code.
 */
class Main {
    static function main() {
        testMap();
        testFilter();
        testFold();
        testExists();
        testForEach();
        testPartition();
        testFlatMap();
    }
    
    /**
     * Test Lambda.map
     * 
     * Expected Elixir:
     * ```elixir
     * result = Enum.map([1, 2, 3], fn x -> x * 2 end)
     * # result is [2, 4, 6] converted to List
     * ```
     */
    static function testMap() {
        var input = [1, 2, 3];
        var doubled = Lambda.map(input, function(x) return x * 2);
        for (item in doubled) {
            trace(item);
        }
    }
    
    /**
     * Test Lambda.filter
     * 
     * Expected Elixir:
     * ```elixir
     * result = Enum.filter([1, 2, 3, 4, 5], fn x -> rem(x, 2) == 0 end)
     * # result is [2, 4] converted to List
     * ```
     */
    static function testFilter() {
        var input = [1, 2, 3, 4, 5];
        var evens = Lambda.filter(input, function(x) return x % 2 == 0);
        for (item in evens) {
            trace(item);
        }
    }
    
    /**
     * Test Lambda.fold (reduce)
     * 
     * Expected Elixir:
     * ```elixir
     * result = Enum.reduce([1, 2, 3, 4], 0, fn item, acc ->
     *   item + acc
     * end)
     * # result is 10
     * ```
     */
    static function testFold() {
        var input = [1, 2, 3, 4];
        var sum = Lambda.fold(input, function(x) return function(acc) return x + acc, 0);
        trace('Sum: $sum');
    }
    
    /**
     * Test Lambda.exists (any)
     * 
     * Expected Elixir:
     * ```elixir
     * result = Enum.any([1, 2, 3, 4], fn x -> x > 3 end)
     * # result is true
     * ```
     */
    static function testExists() {
        var input = [1, 2, 3, 4];
        var hasLarge = Lambda.exists(input, function(x) return x > 3);
        trace('Has value > 3: $hasLarge');
    }
    
    /**
     * Test Lambda.foreach (all)
     * 
     * Expected Elixir:
     * ```elixir
     * result = Enum.all([2, 4, 6], fn x -> rem(x, 2) == 0 end)
     * # result is true
     * ```
     */
    static function testForEach() {
        var input = [2, 4, 6];
        var allEven = Lambda.foreach(input, function(x) return x % 2 == 0);
        trace('All even: $allEven');
    }
    
    /**
     * Test Lambda.partition (split_with)
     * 
     * Expected Elixir:
     * ```elixir
     * {evens, odds} = Enum.split_with([1, 2, 3, 4, 5], fn x ->
     *   rem(x, 2) == 0
     * end)
     * # evens is [2, 4], odds is [1, 3, 5]
     * ```
     */
    static function testPartition() {
        var input = [1, 2, 3, 4, 5];
        var result = Lambda.partition(input, function(x) return x % 2 == 0);
        
        trace("Even numbers:");
        for (item in result.trues) {
            trace(item);
        }
        
        trace("Odd numbers:");
        for (item in result.falses) {
            trace(item);
        }
    }
    
    /**
     * Test Lambda.flatMap
     * 
     * Expected Elixir:
     * ```elixir
     * result = Enum.flat_map([1, 2, 3], fn x ->
     *   [x, x * 2]
     * end)
     * # result is [1, 2, 2, 4, 3, 6] converted to List
     * ```
     */
    static function testFlatMap() {
        var input = [1, 2, 3];
        var result = Lambda.flatMap(input, function(x) return [x, x * 2]);
        
        trace("FlatMap result:");
        for (item in result) {
            trace(item);
        }
    }
}