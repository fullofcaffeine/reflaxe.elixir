// Test for Map iteration patterns and infrastructure variable elimination
// This test demonstrates all Map iteration patterns that need idiomatic Elixir generation

class Main {
    static function main() {
        // Test 1: Simple Map iteration with both key and value
        testSimpleMapIteration();
        
        // Test 2: Key-only iteration (value unused)
        testKeyOnlyIteration();
        
        // Test 3: Value-only iteration (key unused)
        testValueOnlyIteration();
        
        // Test 4: Map comprehension with transformation
        testMapComprehension();
        
        // Test 5: Nested Map iterations
        testNestedMapIteration();
        
        // Test 6: Map iteration with filtering
        testMapIterationWithFilter();
        
        // Test 7: Map iteration with accumulation
        testMapIterationWithAccumulation();
    }
    
    // Test 1: Simple Map iteration with both key and value
    static function testSimpleMapIteration() {
        var colors = new Map<String, String>();
        colors.set("red", "#FF0000");
        colors.set("green", "#00FF00");
        colors.set("blue", "#0000FF");
        
        trace("Simple Map iteration:");
        for (name => hex in colors) {
            trace('Color $name has hex value $hex');
        }
    }
    
    // Test 2: Key-only iteration (value should be _)
    static function testKeyOnlyIteration() {
        var inventory = new Map<String, Int>();
        inventory.set("apples", 10);
        inventory.set("oranges", 5);
        inventory.set("bananas", 8);
        
        trace("Key-only iteration:");
        var keys = [];
        for (item => _ in inventory) {
            keys.push(item);
        }
        trace('Items in inventory: ${keys.join(", ")}');
    }
    
    // Test 3: Value-only iteration (key should be _)
    static function testValueOnlyIteration() {
        var scores = new Map<String, Int>();
        scores.set("Alice", 95);
        scores.set("Bob", 87);
        scores.set("Charlie", 92);
        
        trace("Value-only iteration:");
        var total = 0;
        for (_ => score in scores) {
            total += score;
        }
        trace('Total score: $total');
    }
    
    // Test 4: Map comprehension with transformation
    static function testMapComprehension() {
        var prices = new Map<String, Float>();
        prices.set("apple", 1.50);
        prices.set("orange", 2.00);
        prices.set("banana", 0.75);
        
        trace("Map comprehension:");
        var discounted = [for (item => price in prices) '$item: $$${price * 0.9}'];
        trace('Discounted prices: ${discounted.join(", ")}');
    }
    
    // Test 5: Nested Map iterations
    static function testNestedMapIteration() {
        var departments = new Map<String, Map<String, Int>>();
        
        var engineering = new Map<String, Int>();
        engineering.set("Alice", 5);
        engineering.set("Bob", 3);
        departments.set("Engineering", engineering);
        
        var sales = new Map<String, Int>();
        sales.set("Charlie", 7);
        sales.set("Diana", 4);
        departments.set("Sales", sales);
        
        trace("Nested Map iteration:");
        for (dept => employees in departments) {
            trace('Department: $dept');
            for (name => years in employees) {
                trace('  $name: $years years');
            }
        }
    }
    
    // Test 6: Map iteration with filtering
    static function testMapIterationWithFilter() {
        var ages = new Map<String, Int>();
        ages.set("Alice", 25);
        ages.set("Bob", 17);
        ages.set("Charlie", 30);
        ages.set("Diana", 16);
        
        trace("Map iteration with filter:");
        var adults = [];
        for (name => age in ages) {
            if (age >= 18) {
                adults.push(name);
            }
        }
        trace('Adults: ${adults.join(", ")}');
    }
    
    // Test 7: Map iteration with accumulation
    static function testMapIterationWithAccumulation() {
        var products = new Map<String, Float>();
        products.set("laptop", 999.99);
        products.set("mouse", 25.50);
        products.set("keyboard", 75.00);
        
        trace("Map iteration with accumulation:");
        var descriptions = [];
        var totalValue = 0.0;
        for (product => price in products) {
            descriptions.push('$product ($$${price})');
            totalValue += price;
        }
        trace('Products: ${descriptions.join(", ")}');
        trace('Total value: $$${totalValue}');
    }
    
    // Helper function for testing
    static function transform(key: String, value: Dynamic): String {
        return '$key:$value';
    }
}