using ArrayTools;
/**
 * Test for Map.set() immutability handling
 * 
 * Ensures that map.set() operations in statement context
 * are properly transformed to include reassignment for Elixir's immutability
 */
class Main {
    static function main() {
        // Test 1: Simple map.set in statement context
        var params = new Map<String, Dynamic>();
        params.set("name", "John");
        params.set("age", 30);
        
        // Test 2: Map.set followed by other operations
        params.set("email", "john@example.com");
        var hasEmail = params.exists("email");
        
        // Test 3: Multiple sets in sequence
        var config = new Map<String, String>();
        config.set("host", "localhost");
        config.set("port", "4000");
        config.set("scheme", "https");
        
        // Test 4: Map.set in conditional
        if (true) {
            config.set("debug", "true");
        }
        
        // Test 5: Map.set in loop
        var data = new Map<String, Int>();
        for (i in 0...5) {
            data.set('item_$i', i * 10);
        }
        
        // Test 6: Nested map operations
        var nested = new Map<String, Map<String, String>>();
        var inner = new Map<String, String>();
        inner.set("key", "value");
        nested.set("section", inner);
        
        // Test 7: Map.get and other operations (shouldn't be affected)
        var name = params.get("name");
        var hasAge = params.exists("age");
        params.remove("email");
        
        // Test 8: Map creation and immediate setting
        var chainTest = new Map<String, String>();
        chainTest.set("a", "1");
        chainTest.set("b", "2");
    }
}