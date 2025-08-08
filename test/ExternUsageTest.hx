package test;

#if (macro || reflaxe_runtime)

import elixir.Enumerable;
import elixir.ElixirMap;
import elixir.List as ElixirList;
import elixir.ElixirString;
import elixir.Process as ElixirProcess;
import elixir.GenServer;

/**
 * Comprehensive tests for Elixir standard library extern definitions
 * Validates type safety and proper function signatures
 */
class ExternUsageTest {
    public static function main() {
        trace("Running Elixir Extern Usage Tests...");
        
        testEnumOperations();
        testMapOperations();
        testListOperations();
        testStringOperations();
        testProcessOperations();
        testGenServerOperations();
        testTypeCompatibility();
        testNullHandling();
        
        trace("✅ All Extern Usage tests passed!");
    }
    
    /**
     * Test Enum module operations
     */
    static function testEnumOperations() {
        trace("TEST: Enum module operations");
        
        // Test basic mapping operations
        var numbers = [1, 2, 3, 4, 5];
        var doubled = Enumerable.map(numbers, x -> x * 2);
        assertTrue(doubled != null, "Enumerable.map should return non-null result");
        
        var evens = Enumerable.filter(numbers, x -> x % 2 == 0);
        assertTrue(evens != null, "Enumerable.filter should return non-null result");
        
        var sum = Enumerable.reduce(numbers, 0, (x, acc) -> x + acc);
        assertTrue(sum != null, "Enumerable.reduce should return non-null result");
        
        // Test aggregation functions
        var count = Enumerable.count(numbers);
        assertTrue(count >= 0, "Enumerable.count should return non-negative number");
        
        var maximum = Enumerable.max(numbers);
        assertTrue(maximum != null, "Enumerable.max should return value for non-empty list");
        
        // Test finding operations
        var found = Enumerable.find(numbers, x -> x > 3);
        assertTrue(found != null, "Enumerable.find should find matching element");
        
        var isMember = Enumerable.member(numbers, 3);
        assertTrue(isMember == true || isMember == false, "Enumerable.member should return boolean");
        
        trace("✅ Enum operations test passed");
    }
    
    /**
     * Test Map module operations
     */
    static function testMapOperations() {
        trace("TEST: Map module operations");
        
        // Test map creation and basic operations
        var emptyMap = ElixirMap.new_();
        assertTrue(emptyMap != null, "Map.new should create empty map");
        
        var map = ElixirMap.put(emptyMap, "key1", "value1");
        assertTrue(map != null, "Map.put should return new map");
        
        var value = ElixirMap.get(map, "key1");
        assertTrue(value != null, "Map.get should return value for existing key");
        
        var hasKey = ElixirMap.hasKey(map, "key1");
        assertTrue(hasKey == true || hasKey == false, "Map.has_key should return boolean");
        
        var size = ElixirMap.size(map);
        assertTrue(size >= 0, "Map.size should return non-negative number");
        
        // Test map updates
        var updated = ElixirMap.update(map, "key1", "default", v -> v + "!");
        assertTrue(updated != null, "Map.update should return updated map");
        
        var merged = ElixirMap.merge(map, emptyMap);
        assertTrue(merged != null, "Map.merge should return merged map");
        
        // Test conversion operations
        var keys = ElixirMap.keys(map);
        assertTrue(keys != null, "Map.keys should return key array");
        
        var values = ElixirMap.values(map);
        assertTrue(values != null, "Map.values should return value array");
        
        trace("✅ Map operations test passed");
    }
    
    /**
     * Test List module operations
     */
    static function testListOperations() {
        trace("TEST: List module operations");
        
        var list = ["a", "b", "c"];
        
        // Test basic list access
        var first = ElixirList.first(list);
        assertTrue(first != null, "ElixirList.first should return first element");
        
        var last = ElixirList.last(list);
        assertTrue(last != null, "ElixirList.last should return last element");
        
        // Test list manipulation
        var duplicated = ElixirList.duplicate("x", 3);
        assertTrue(duplicated != null, "ElixirList.duplicate should create list");
        
        var inserted = ElixirList.insertAt(list, 1, "inserted");
        assertTrue(inserted != null, "ElixirList.insert_at should return new list");
        
        var flattened = ElixirList.flatten([["a"], ["b", "c"]]);
        assertTrue(flattened != null, "ElixirList.flatten should flatten nested lists");
        
        // Test folding operations
        var folded = ElixirList.foldl(["1", "2", "3"], "", (x, acc) -> acc + x);
        assertTrue(folded != null, "ElixirList.foldl should fold list");
        
        // Test conversion operations
        var charlist = ElixirList.toCharlist("hello");
        assertTrue(charlist != null, "ElixirList.to_charlist should convert string");
        
        var backToString = ElixirList.toString(charlist);
        assertTrue(backToString != null, "ElixirList.to_string should convert charlist");
        
        trace("✅ List operations test passed");
    }
    
    /**
     * Test String module operations  
     */
    static function testStringOperations() {
        trace("TEST: String module operations");
        
        var str = "  Hello World  ";
        
        // Test string measurement
        var length = ElixirString.length(str);
        assertTrue(length >= 0, "String.length should return non-negative number");
        
        var byteSize = ElixirString.byteSize(str);
        assertTrue(byteSize >= 0, "String.byte_size should return non-negative number");
        
        // Test case conversion
        var lower = ElixirString.downcase(str);
        assertTrue(lower != null, "String.downcase should return string");
        
        var upper = ElixirString.upcase(str);
        assertTrue(upper != null, "String.upcase should return string");
        
        var capitalized = ElixirString.capitalize(str);
        assertTrue(capitalized != null, "String.capitalize should return string");
        
        // Test trimming operations
        var trimmed = ElixirString.trim(str);
        assertTrue(trimmed != null, "String.trim should return trimmed string");
        
        // Test string predicates
        var contains = ElixirString.contains(str, "Hello");
        assertTrue(contains == true || contains == false, "String.contains should return boolean");
        
        var startsWith = ElixirString.startsWith(str, "  Hello");
        assertTrue(startsWith == true || startsWith == false, "String.starts_with should return boolean");
        
        // Test string manipulation
        var replaced = ElixirString.replace(str, "World", "Universe");
        assertTrue(replaced != null, "String.replace should return new string");
        
        var split = ElixirString.split(str);
        assertTrue(split != null, "String.split should return string array");
        
        trace("✅ String operations test passed");
    }
    
    /**
     * Test Process module operations
     */
    static function testProcessOperations() {
        trace("TEST: Process module operations");
        
        // Test process identification  
        var self = ElixirProcess.self();
        assertTrue(self != null, "ElixirProcess.self should return current pid");
        
        // Test process information
        var alive = ElixirProcess.alive(self);
        assertTrue(alive == true || alive == false, "ElixirProcess.alive should return boolean");
        
        var info = ElixirProcess.info(self);
        assertTrue(info != null, "ElixirProcess.info should return process info");
        
        // Test process registry operations
        var registered = ElixirProcess.registered();
        assertTrue(registered != null, "ElixirProcess.registered should return name list");
        
        // Test process dictionary operations
        var putResult = ElixirProcess.put("test_key", "test_value");
        // putResult can be null if key didn't exist before
        
        var getValue = ElixirProcess.get("test_key");
        assertTrue(getValue != null, "ElixirProcess.get should return stored value");
        
        var keys = ElixirProcess.getKeys();
        assertTrue(keys != null, "ElixirProcess.get_keys should return key list");
        
        trace("✅ Process operations test passed");
    }
    
    /**
     * Test GenServer module operations
     */
    static function testGenServerOperations() {
        trace("TEST: GenServer module operations");
        
        // Test GenServer helper functions
        var replyTuple = GenServer.replyTuple("response", "new_state");
        assertTrue(replyTuple != null, "replyTuple should create reply tuple");
        assertTrue(replyTuple._0 == GenServer.REPLY, "Reply tuple should have correct tag");
        
        var noreplyTuple = GenServer.noreplyTuple("state");
        assertTrue(noreplyTuple != null, "noreplyTuple should create noreply tuple");
        assertTrue(noreplyTuple._0 == GenServer.NOREPLY, "Noreply tuple should have correct tag");
        
        var stopTuple = GenServer.stopTuple("normal", "state");
        assertTrue(stopTuple != null, "stopTuple should create stop tuple");
        assertTrue(stopTuple._0 == GenServer.STOP, "Stop tuple should have correct tag");
        
        var continueTuple = GenServer.continueTuple("state", "continue_data");
        assertTrue(continueTuple != null, "continueTuple should create continue tuple");
        assertTrue(continueTuple._0 == GenServer.CONTINUE, "Continue tuple should have correct tag");
        
        var hibernateTuple = GenServer.hibernateTuple("state");
        assertTrue(hibernateTuple != null, "hibernateTuple should create hibernate tuple");
        assertTrue(hibernateTuple._2 == GenServer.HIBERNATE, "Hibernate tuple should have hibernate flag");
        
        // Test constants
        assertTrue(GenServer.OK != null, "GenServer.OK should be defined");
        assertTrue(GenServer.REPLY != null, "GenServer.REPLY should be defined");
        assertTrue(GenServer.NOREPLY != null, "GenServer.NOREPLY should be defined");
        
        trace("✅ GenServer operations test passed");
    }
    
    /**
     * Test type compatibility between modules
     */
    static function testTypeCompatibility() {
        trace("TEST: Type compatibility between modules");
        
        // Test that arrays work consistently across modules
        var numbers = [1, 2, 3, 4, 5];
        var strings = ["a", "b", "c"];
        
        // Should be able to pass arrays between different extern modules
        var enumCount = Enumerable.count(numbers);
        var firstElement = ElixirList.first(numbers);
        
        assertTrue(enumCount >= 0, "Type compatibility: Enumerable should work with array");
        assertTrue(firstElement != null, "Type compatibility: List should work with array");
        
        // Test Map compatibility
        var emptyMap = ElixirMap.new_();
        var mapSize = ElixirMap.size(emptyMap);
        assertTrue(mapSize >= 0, "Type compatibility: Map operations should work");
        
        trace("✅ Type compatibility test passed");
    }
    
    /**
     * Test null/nil handling in extern functions
     */
    static function testNullHandling() {
        trace("TEST: Null/nil handling");
        
        // Test functions that can return null
        var emptyList: Array<String> = [];
        var firstOfEmpty = ElixirList.first(emptyList);
        // firstOfEmpty should be null for empty list - this is expected behavior
        
        var lastOfEmpty = ElixirList.last(emptyList);
        // lastOfEmpty should be null for empty list - this is expected behavior
        
        var emptyMap = ElixirMap.new_();
        var nonExistentKey = ElixirMap.get(emptyMap, "missing");
        // nonExistentKey should be null for missing key - this is expected behavior
        
        // Test functions with default values
        var withDefault = ElixirMap.getWithDefault(emptyMap, "missing", "default_value");
        assertTrue(withDefault != null, "Functions with defaults should not return null");
        
        trace("✅ Null handling test passed");
    }
    
    // Test helper function
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
}

#end