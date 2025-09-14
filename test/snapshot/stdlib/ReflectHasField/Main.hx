/**
 * Test for Reflect.hasField transformation to Map.has_key?
 * 
 * WHY: Verify that Reflect.hasField properly transforms to Map.has_key?
 * with correct atom conversion for field names.
 * 
 * WHAT: Tests various Reflect.hasField patterns:
 * - String literal field names
 * - Variable field names
 * - CamelCase to snake_case conversion
 * - Nested object field checking
 * 
 * HOW: Calls Reflect.hasField with different patterns and verifies
 * the generated Elixir code uses Map.has_key? with proper atoms.
 */
class Main {
    public static function main() {
        // Test with anonymous object
        var obj = {
            name: "John",
            age: 30,
            isActive: true,
            nestedData: {
                streetAddress: "123 Main St"
            }
        };
        
        // Test with string literal field names
        var hasName: Bool = Reflect.hasField(obj, "name");
        var hasAge: Bool = Reflect.hasField(obj, "age");
        var hasEmail: Bool = Reflect.hasField(obj, "email"); // Should be false
        
        // Test with camelCase field names (should convert to snake_case)
        var hasIsActive: Bool = Reflect.hasField(obj, "isActive");
        var hasNestedData: Bool = Reflect.hasField(obj, "nestedData");
        
        // Test with variable field name
        var fieldName: String = "name";
        var hasFieldDynamic: Bool = Reflect.hasField(obj, fieldName);
        
        // Test with nested object
        var hasStreetAddress: Bool = Reflect.hasField(obj.nestedData, "streetAddress");
        
        // Test other Reflect methods for comparison
        var nameValue = Reflect.field(obj, "name");
        var fields = Reflect.fields(obj);
        
        // Use deleteField to test mutation
        var objWithoutAge = Reflect.deleteField(obj, "age");
        var stillHasAge: Bool = Reflect.hasField(objWithoutAge, "age");
        
        // Test with setField
        var objWithEmail = Reflect.setField(obj, "email", "john@example.com");
        var nowHasEmail: Bool = Reflect.hasField(objWithEmail, "email");
        
        // Output results for verification
        trace('Has name: $hasName');
        trace('Has age: $hasAge');
        trace('Has email: $hasEmail');
        trace('Has isActive: $hasIsActive');
        trace('Has nestedData: $hasNestedData');
        trace('Has field (dynamic): $hasFieldDynamic');
        trace('Has streetAddress: $hasStreetAddress');
        trace('Still has age after delete: $stillHasAge');
        trace('Has email after set: $nowHasEmail');
        trace('Fields: $fields');
    }
}