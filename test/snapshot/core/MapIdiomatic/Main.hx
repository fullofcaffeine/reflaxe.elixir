package;

using ArrayTools;
/**
 * Test idiomatic Map transformations
 * 
 * This test validates that all Map operations are transformed from
 * OOP-style Haxe code to idiomatic functional Elixir patterns.
 * 
 * BEFORE (OOP-style):   map.set("key", value)
 * AFTER (Functional):   Map.put(map, "key", value)
 */
class Main {
    public static function main() {
        testMapConstruction();
        testBasicMapOperations();
        testMapQueries();
        testMapTransformations();
        testMapUtilities();
        
        trace("Map idiomatic transformation tests complete");
    }
    
    /**
     * Test Map construction transforms
     * new Map() should become %{}
     * new Map(data) should become Map.new(data)
     */
    static function testMapConstruction() {
        trace("=== Map Construction ===");
        
        // Empty map construction
        var emptyMap = new Map<String, Int>();
        trace('Empty map: ${emptyMap}');
        
        // Map with initial data (when available)
        var initialData = ["key1" => 1, "key2" => 2];
        // Note: This would need special handling for literal syntax
        
        trace("Map construction tests complete");
    }
    
    /**
     * Test basic Map operations: set, get, remove, exists
     * These should transform to Map.put, Map.get, Map.delete, Map.has_key?
     */
    static function testBasicMapOperations() {
        trace("=== Basic Map Operations ===");
        
        var map = new Map<String, String>();
        
        // map.set() → Map.put()
        map.set("name", "Alice");
        map.set("city", "Portland");
        map.set("job", "Developer");
        
        // map.get() → Map.get()
        var name = map.get("name");
        var city = map.get("city");
        var missing = map.get("missing");
        
        trace('Name: ${name}');
        trace('City: ${city}');
        trace('Missing: ${missing}');
        
        // map.exists() → Map.has_key?()
        var hasName = map.exists("name");
        var hasMissing = map.exists("missing");
        
        trace('Has name: ${hasName}');
        trace('Has missing: ${hasMissing}');
        
        // map.remove() → Map.delete()
        map.remove("job");
        var jobAfterRemove = map.get("job");
        trace('Job after remove: ${jobAfterRemove}');
        
        // map.clear() → %{}
        map.clear();
        
        // Check if cleared by trying to get a key
        var valueAfterClear = map.get("name");
        trace('Value after clear: ${valueAfterClear}');
    }
    
    /**
     * Test Map query operations: keys, values, size, isEmpty
     * These should transform to Map.keys, Map.values, map_size, etc.
     */
    static function testMapQueries() {
        trace("=== Map Query Operations ===");
        
        var map = new Map<String, Int>();
        map.set("a", 1);
        map.set("b", 2);
        map.set("c", 3);
        
        // map.keys() → Map.keys()
        var keys = map.keys();
        trace('Keys: ${keys}');
        
        // map.iterator() → Map.values() (for values iterator)
        var values = map.iterator();
        trace('Values iterator: ${values}');
        
        // Note: Haxe Map doesn't have size() or isEmpty() methods
        // We can check emptiness by trying to get keys
        var hasKeys = false;
        for (key in map.keys()) {
            hasKeys = true;
            break;
        }
        trace('Map has keys: ${hasKeys}');
        
        var emptyMap = new Map<String, Int>();
        var emptyHasKeys = false;
        for (key in emptyMap.keys()) {
            emptyHasKeys = true;
            break;
        }
        trace('Empty map has keys: ${emptyHasKeys}');
    }
    
    /**
     * Test Map transformations and iterations
     * These should work with Elixir's functional iteration patterns
     */
    static function testMapTransformations() {
        trace("=== Map Transformations ===");
        
        var numbers = new Map<String, Int>();
        numbers.set("one", 1);
        numbers.set("two", 2);
        numbers.set("three", 3);
        
        // Iterate over map - should use Map.to_list or similar
        trace("Iterating over map:");
        for (key in numbers.keys()) {
            var value = numbers.get(key);
            trace('  ${key} => ${value}');
        }
        
        // Copy operation
        var copied = numbers.copy();
        
        // Check copy by getting a key
        var copiedValue = copied.get("one");
        trace('Copied map value for "one": ${copiedValue}');
        
        // Test with different key types
        var intMap = new Map<Int, String>();
        intMap.set(1, "first");
        intMap.set(2, "second");
        
        trace("Int-keyed map:");
        for (key in intMap.keys()) {
            var value = intMap.get(key);
            trace('  ${key} => ${value}');
        }
    }
    
    /**
     * Test Map utility operations: toString, copy, etc.
     */
    static function testMapUtilities() {
        trace("=== Map Utilities ===");
        
        var map = new Map<String, Dynamic>();
        map.set("string", "hello");
        map.set("number", 42);
        map.set("boolean", true);
        
        // map.toString() → inspect()
        var stringRepr = map.toString();
        trace('String representation: ${stringRepr}');
        
        // Ensure all types work
        var stringVal = map.get("string");
        var numberVal = map.get("number");
        var boolVal = map.get("boolean");
        
        trace('String value: ${stringVal}');
        trace('Number value: ${numberVal}');
        trace('Boolean value: ${boolVal}');
    }
    
    /**
     * Test edge cases and special scenarios
     */
    static function testEdgeCases() {
        trace("=== Edge Cases ===");
        
        // Null key handling
        var map = new Map<String, String>();
        map.set("", "empty string key");
        var emptyKeyValue = map.get("");
        trace('Empty string key value: ${emptyKeyValue}');
        
        // Overwriting existing keys
        map.set("key", "first");
        map.set("key", "second");
        var overwritten = map.get("key");
        trace('Overwritten value: ${overwritten}');
        
        // Chain operations (if supported)
        var result = new Map<String, Int>();
        result.set("a", 1);
        result.set("b", 2);
        
        // Check final result
        var finalA = result.get("a");
        var finalB = result.get("b");
        trace('Final values after chaining: a=${finalA}, b=${finalB}');
    }
}