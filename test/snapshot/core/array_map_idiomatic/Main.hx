/**
 * Test idiomatic array map compilation
 * 
 * CRITICAL BUG: Array map operations are generating broken code with
 * module-level variables instead of using idiomatic Enum.map
 * 
 * Expected: tags.map(t -> expr) should compile to Enum.map(tags, fn t -> expr end)
 * Actual: Generates manual loops with variables g, g1, g2 at module level
 * 
 * This test ensures array operations compile to idiomatic Elixir patterns.
 */
class Main {
    static function main() {
        // Test 1: Simple array map
        testSimpleMap();
        
        // Test 2: Map with enum construction (the bug case)
        testMapWithEnumConstruction();
        
        // Test 3: Nested array operations
        testNestedOperations();
        
        // Test 4: Array filter
        testArrayFilter();
        
        // Test 5: Array reduce/fold - skipped (Haxe arrays don't have fold)
        // testArrayReduce();
        
        // Test 6: Complex transformations
        testComplexTransformations();
    }
    
    static function testSimpleMap() {
        var numbers = [1, 2, 3, 4, 5];
        
        // Simple map - should compile to Enum.map
        var doubled = numbers.map(n -> n * 2);
        
        // Map with type change
        var strings = numbers.map(n -> 'Number: $n');
        
        // Map with function call
        var processed = numbers.map(n -> processNumber(n));
    }
    
    static function testMapWithEnumConstruction() {
        // This is the exact pattern that's broken in todo-app
        var tags: Array<String> = ["work", "personal", "urgent"];
        
        // Map to enum values (simulating ChangesetValue.StringValue)
        var values = tags.map(t -> StringValue(t));
        
        // Map to tuples (simulating the actual case)
        var tuples = tags.map(t -> {type: "string", value: t});
        
        // Map with nested enum construction
        var nested = tags.map(t -> ArrayValue([StringValue(t)]));
    }
    
    static function testNestedOperations() {
        var matrix = [[1, 2], [3, 4], [5, 6]];
        
        // Nested map - should use nested Enum.map
        var doubled = matrix.map(row -> row.map(n -> n * 2));
        
        // Map then filter
        var filtered = matrix.map(row -> row.filter(n -> n > 2));
    }
    
    static function testArrayFilter() {
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        
        // Simple filter - should compile to Enum.filter
        var evens = numbers.filter(n -> n % 2 == 0);
        
        // Filter with complex condition
        var inRange = numbers.filter(n -> n > 3 && n < 8);
        
        // Chained operations
        var result = numbers
            .filter(n -> n > 5)
            .map(n -> n * 2);
    }
    
    // Commented out - Haxe arrays don't have fold
    // static function testArrayReduce() {
    //     var numbers = [1, 2, 3, 4, 5];
    //     
    //     // Sum using fold - should compile to Enum.reduce
    //     var sum = numbers.fold((acc, n) -> acc + n, 0);
    //     
    //     // Build string
    //     var str = numbers.fold((acc, n) -> acc + ", " + n, "Numbers:");
    //     
    //     // Complex accumulator
    //     var result = numbers.fold((acc, n) -> {
    //         acc.sum += n;
    //         acc.count++;
    //         return acc;
    //     }, {sum: 0, count: 0});
    // }
    
    static function testComplexTransformations() {
        var users = [
            {name: "Alice", age: 30},
            {name: "Bob", age: 25},
            {name: "Charlie", age: 35}
        ];
        
        // Complex map operation
        var userInfo = users.map(u -> {
            name: u.name.toUpperCase(),
            ageGroup: u.age < 30 ? "young" : "adult",
            id: generateId(u.name)
        });
        
        // Filter and map combination
        var adults = users
            .filter(u -> u.age >= 30)
            .map(u -> u.name);
        
        // Multiple transformations
        var processed = users
            .filter(u -> u.age > 20)
            .map(u -> {name: u.name, valid: true})
            .filter(u -> u.valid)
            .map(u -> u.name);
    }
    
    // Helper functions
    static function processNumber(n: Int): String {
        return 'Processed: $n';
    }
    
    static function generateId(name: String): Int {
        return name.length * 100;
    }
    
    // Enum simulation (like ChangesetValue)
    static function StringValue(s: String): Dynamic {
        return {type: "StringValue", value: s};
    }
    
    static function ArrayValue(arr: Array<Dynamic>): Dynamic {
        return {type: "ArrayValue", items: arr};
    }
}