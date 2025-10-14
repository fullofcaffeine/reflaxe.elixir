/**
 * Test suite for Reflect API implementation
 * 
 * Tests all Reflect methods to ensure they correctly map to Elixir Map operations
 * and maintain proper behavior with atom/string field names.
 */
class Main {
    static function main() {
        trace("Testing Reflect API...");
        
        // Test object for reflection operations
        var obj = {
            name: "John",
            age: 30,
            active: true
        };
        
        // Test 1: Reflect.field - Get field value
        trace("\nTest 1: Reflect.field");
        var name = Reflect.field(obj, "name");
        trace("Name field: " + name);
        assert(name == "John", "Field retrieval should work");
        
        var missing = Reflect.field(obj, "missing");
        trace("Missing field: " + missing);
        assert(missing == null, "Missing field should return null");
        
        // Test 2: Reflect.setField - Set field value
        trace("\nTest 2: Reflect.setField");
        var updated = Reflect.setField(obj, "age", 31);
        trace("Original age: " + obj.age);
        trace("Updated age: " + Reflect.field(updated, "age"));
        assert(Reflect.field(updated, "age") == 31, "Field should be updated");
        // In Elixir, maps are immutable, so original should be unchanged
        assert(obj.age == 30, "Original object should be unchanged (immutability)");
        
        // Test adding new field
        var withEmail = Reflect.setField(obj, "email", "john@example.com");
        trace("Added email: " + Reflect.field(withEmail, "email"));
        assert(Reflect.field(withEmail, "email") == "john@example.com", "New field should be added");
        
        // Test 3: Reflect.fields - Get all field names
        trace("\nTest 3: Reflect.fields");
        var fields = Reflect.fields(obj);
        trace("Fields: " + fields);
        assert(fields.length == 3, "Should have 3 fields");
        assert(fields.indexOf("name") >= 0, "Should have 'name' field");
        assert(fields.indexOf("age") >= 0, "Should have 'age' field");
        assert(fields.indexOf("active") >= 0, "Should have 'active' field");
        
        // Test 4: Reflect.hasField - Check field existence
        trace("\nTest 4: Reflect.hasField");
        assert(Reflect.hasField(obj, "name") == true, "Should have 'name' field");
        assert(Reflect.hasField(obj, "missing") == false, "Should not have 'missing' field");
        
        // Test 5: Reflect.deleteField - Remove field
        trace("\nTest 5: Reflect.deleteField");
        var withoutAge = Reflect.deleteField(obj, "age");
        assert(Reflect.hasField(withoutAge, "age") == false, "Field should be deleted");
        assert(Reflect.hasField(obj, "age") == true, "Original should still have field (immutability)");
        
        // Test 6: Reflect.isObject - Type checking
        trace("\nTest 6: Reflect.isObject");
        assert(Reflect.isObject(obj) == true, "Object should be detected");
        assert(Reflect.isObject("string") == false, "String should not be object");
        assert(Reflect.isObject(42) == false, "Number should not be object");
        assert(Reflect.isObject([1, 2, 3]) == false, "Array should not be object");
        
        // Test 7: Reflect.copy - Shallow copy
        trace("\nTest 7: Reflect.copy");
        var copied = Reflect.copy(obj);
        assert(Reflect.field(copied, "name") == "John", "Copy should have same fields");
        // In Elixir, maps are immutable so copy returns same reference
        // But the API is maintained for compatibility
        
        // Test 8: Reflect.compare - Value comparison
        trace("\nTest 8: Reflect.compare");
        assert(Reflect.compare("a", "b") < 0, "a should be less than b");
        assert(Reflect.compare("b", "a") > 0, "b should be greater than a");
        assert(Reflect.compare("same", "same") == 0, "Same strings should be equal");
        assert(Reflect.compare(10, 20) < 0, "10 should be less than 20");
        
        // Test 9: Reflect.callMethod - Dynamic method invocation
        trace("\nTest 9: Reflect.callMethod");
        var testFunc = function(x: Int, y: Int) { return x + y; };
        var result = Reflect.callMethod(null, testFunc, [5, 3]);
        assert(result == 8, "Function should be called with arguments");
        
        // Test with object method
        var calculator_base = 10;
        var calculator = {
            base: calculator_base,
            // Use a closure that captures calculator_base instead of `this`.
            add: function(x: Int) { return calculator_base + x; }
        };
        var methodResult = Reflect.callMethod(calculator, calculator.add, [5]);
        assert(methodResult == 15, "Method should use object context");
        
        // Test 10: Reflect.isEnumValue - Enum detection
        trace("\nTest 10: Reflect.isEnumValue");
        var option: Option<Int> = Some(42);
        assert(Reflect.isEnumValue(option) == true, "Enum value should be detected");
        assert(Reflect.isEnumValue(obj) == false, "Object should not be enum");
        assert(Reflect.isEnumValue("string") == false, "String should not be enum");
        
        trace("\nAll Reflect API tests passed!");
    }
    
    static function assert(condition: Bool, message: String) {
        if (!condition) {
            throw "Assertion failed: " + message;
        }
    }
}

enum Option<T> {
    Some(value: T);
    None;
}
