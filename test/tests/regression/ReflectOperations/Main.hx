class Main {
    public static function main() {
        // Test object with both string and atom-like field names
        var obj = {
            name: "John",
            age: 30,
            isActive: true,
            nested_data: {
                street_address: "123 Main St",
                zip_code: "12345"
            }
        };
        
        // Test Reflect.hasField - should convert string to atom for checking
        var hasName: Bool = Reflect.hasField(obj, "name");
        var hasAge: Bool = Reflect.hasField(obj, "age");
        var hasEmail: Bool = Reflect.hasField(obj, "email");  // Should be false
        var hasNestedData: Bool = Reflect.hasField(obj, "nested_data");
        
        // Test Reflect.field - should convert string to atom for access
        var name: String = Reflect.field(obj, "name");
        var age: Int = Reflect.field(obj, "age");
        var nestedData = Reflect.field(obj, "nested_data");
        
        // Test Reflect.setField - should convert string to atom for setting
        var mutableObj = {x: 10, y: 20};
        Reflect.setField(mutableObj, "z", 30);
        var hasZ: Bool = Reflect.hasField(mutableObj, "z");
        var zValue: Int = Reflect.field(mutableObj, "z");
        
        // Test Reflect.deleteField - should convert string to atom for deletion
        var deletableObj = {a: 1, b: 2, c: 3};
        Reflect.deleteField(deletableObj, "b");
        var hasB: Bool = Reflect.hasField(deletableObj, "b");  // Should be false
        
        // Test Reflect.fields - should return field names
        var fields = Reflect.fields(obj);
        
        // Test Reflect.isObject
        var isObjObject: Bool = Reflect.isObject(obj);
        var isStringObject: Bool = Reflect.isObject("not an object");
        var isNumberObject: Bool = Reflect.isObject(42);
        
        // Test Reflect.copy - in Elixir, objects are immutable so copy just returns the object
        var copied = Reflect.copy(obj);
        
        // Output for verification
        trace("hasName: " + hasName);  // Should be true
        trace("hasAge: " + hasAge);  // Should be true
        trace("hasEmail: " + hasEmail);  // Should be false
        trace("hasNestedData: " + hasNestedData);  // Should be true
        
        trace("name: " + name);  // Should be "John"
        trace("age: " + age);  // Should be 30
        
        trace("hasZ after setField: " + hasZ);  // Should be true
        trace("zValue: " + zValue);  // Should be 30
        
        trace("hasB after deleteField: " + hasB);  // Should be false
        
        trace("fields length: " + fields.length);  // Should be 4
        
        trace("isObjObject: " + isObjObject);  // Should be true
        trace("isStringObject: " + isStringObject);  // Should be false
        trace("isNumberObject: " + isNumberObject);  // Should be false
    }
}