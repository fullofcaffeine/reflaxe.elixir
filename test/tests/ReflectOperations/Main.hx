/**
 * Comprehensive test suite for Reflect module functions
 * Tests all reflection operations with various object types
 */
class Main {
    public static function main() {
        testFieldOperations();
        testFieldListing();
        testObjectChecking();
        testComparison();
        testEnumDetection();
        testMethodCalling();
    }
    
    static function testFieldOperations() {
        // Create test objects
        var obj = { name: "Alice", age: 30, active: true };
        var nested = { 
            user: { id: 1, name: "Bob" },
            settings: { theme: "dark", notifications: true }
        };
        
        // Test Reflect.field() - getting fields
        var name = Reflect.field(obj, "name");
        var age = Reflect.field(obj, "age");
        var missing = Reflect.field(obj, "nonexistent");
        var nestedName = Reflect.field(Reflect.field(nested, "user"), "name");
        
        trace("Field retrieval:");
        trace('  obj.name: $name');
        trace('  obj.age: $age');
        trace('  obj.nonexistent: $missing');
        trace('  nested.user.name: $nestedName');
        
        // Test Reflect.setField() - setting fields (creates new object in Elixir)
        var updated = Reflect.setField(obj, "age", 31);
        var newField = Reflect.setField(obj, "city", "New York");
        
        trace("Field setting (immutable):");
        trace('  Updated age: ${Reflect.field(updated, "age")}');
        trace('  New field city: ${Reflect.field(newField, "city")}');
        
        // Test Reflect.hasField() - checking field existence
        var hasName = Reflect.hasField(obj, "name");
        var hasCity = Reflect.hasField(obj, "city");
        var hasNested = Reflect.hasField(nested, "user");
        
        trace("Field existence:");
        trace('  Has name: $hasName');
        trace('  Has city: $hasCity');
        trace('  Has user: $hasNested');
        
        // Test Reflect.deleteField() - removing fields (creates new object)
        var deleted = Reflect.deleteField(obj, "age");
        var deletedMissing = Reflect.deleteField(obj, "nonexistent");
        
        trace("Field deletion:");
        trace('  After deleting age: ${Reflect.hasField(deleted, "age")}');
        trace('  Delete nonexistent: ${Reflect.field(deletedMissing, "name")}');
    }
    
    static function testFieldListing() {
        var simple = { x: 10, y: 20 };
        var complex = { 
            id: 1,
            name: "Test",
            active: true,
            data: [1, 2, 3],
            meta: { created: "2024-01-01" }
        };
        var empty = {};
        
        // Test Reflect.fields() - getting all field names
        var simpleFields = Reflect.fields(simple);
        var complexFields = Reflect.fields(complex);
        var emptyFields = Reflect.fields(empty);
        
        trace("Field listing:");
        trace('  Simple object fields: [${simpleFields.join(", ")}]');
        trace('  Complex object fields: [${complexFields.join(", ")}]');
        trace('  Empty object fields: [${emptyFields.join(", ")}]');
    }
    
    static function testObjectChecking() {
        var obj = { field: "value" };
        var str = "string";
        var num = 42;
        var arr = [1, 2, 3];
        var nul = null;
        var fun = function(x: Int) return x * 2;
        
        // Test Reflect.isObject() - checking if value is an object/map
        var objIsObject = Reflect.isObject(obj);
        var strIsObject = Reflect.isObject(str);
        var numIsObject = Reflect.isObject(num);
        var arrIsObject = Reflect.isObject(arr);
        var nullIsObject = Reflect.isObject(nul);
        var funIsObject = Reflect.isObject(fun);
        
        trace("Object type checking:");
        trace('  Object is object: $objIsObject');
        trace('  String is object: $strIsObject');
        trace('  Number is object: $numIsObject');
        trace('  Array is object: $arrIsObject');
        trace('  Null is object: $nullIsObject');
        trace('  Function is object: $funIsObject');
        
        // Test Reflect.copy() - shallow copying (in Elixir, just returns same immutable map)
        var original = { a: 1, b: { c: 2 } };
        var copied = Reflect.copy(original);
        
        trace("Object copying:");
        trace('  Original a: ${Reflect.field(original, "a")}');
        trace('  Copied a: ${Reflect.field(copied, "a")}');
    }
    
    static function testComparison() {
        // Test Reflect.compare() with various types
        var cmpInts = Reflect.compare(5, 10);
        var cmpEqual = Reflect.compare(42, 42);
        var cmpStrings = Reflect.compare("apple", "banana");
        var cmpFloats = Reflect.compare(3.14, 2.71);
        var cmpBools = Reflect.compare(true, false);
        var cmpArrays = Reflect.compare([1, 2], [1, 3]);
        
        trace("Value comparison:");
        trace('  5 vs 10: $cmpInts');
        trace('  42 vs 42: $cmpEqual');
        trace('  "apple" vs "banana": $cmpStrings');
        trace('  3.14 vs 2.71: $cmpFloats');
        trace('  true vs false: $cmpBools');
        trace('  [1,2] vs [1,3]: $cmpArrays');
    }
    
    static function testEnumDetection() {
        var opt1 = Some("value");
        var opt2 = None;
        var res1 = Ok(42);
        var res2 = Error("failed");
        
        var str = "not an enum";
        var obj = { field: "value" };
        var num = 123;
        
        // Test Reflect.isEnumValue()
        var opt1IsEnum = Reflect.isEnumValue(opt1);
        var opt2IsEnum = Reflect.isEnumValue(opt2);
        var res1IsEnum = Reflect.isEnumValue(res1);
        var res2IsEnum = Reflect.isEnumValue(res2);
        var strIsEnum = Reflect.isEnumValue(str);
        var objIsEnum = Reflect.isEnumValue(obj);
        var numIsEnum = Reflect.isEnumValue(num);
        
        trace("Enum value detection:");
        trace('  Some("value") is enum: $opt1IsEnum');
        trace('  None is enum: $opt2IsEnum');
        trace('  Ok(42) is enum: $res1IsEnum');
        trace('  Error("failed") is enum: $res2IsEnum');
        trace('  String is enum: $strIsEnum');
        trace('  Object is enum: $objIsEnum');
        trace('  Number is enum: $numIsEnum');
    }
    
    static function testMethodCalling() {
        // Test functions
        var add = function(a: Int, b: Int) return a + b;
        var multiply = function(x: Int, y: Int) return x * y;
        var greet = function(name: String) return 'Hello, $name!';
        var noArgs = function() return "No arguments";
        
        // Test Reflect.callMethod() with various argument counts
        var sum = Reflect.callMethod(null, add, [10, 20]);
        var product = Reflect.callMethod(null, multiply, [5, 6]);
        var greeting = Reflect.callMethod(null, greet, ["World"]);
        var noArgsResult = Reflect.callMethod(null, noArgs, []);
        
        trace("Dynamic method calling:");
        trace('  add(10, 20): $sum');
        trace('  multiply(5, 6): $product');
        trace('  greet("World"): $greeting');
        trace('  noArgs(): $noArgsResult');
        
        // Test with object methods
        var calculator = {
            value: 100,
            addTo: function(n: Int) return n + 100,
            multiplyBy: function(n: Int) return n * 2
        };
        
        var added = Reflect.callMethod(calculator, Reflect.field(calculator, "addTo"), [50]);
        var multiplied = Reflect.callMethod(calculator, Reflect.field(calculator, "multiplyBy"), [25]);
        
        trace("Object method calling:");
        trace('  calculator.addTo(50): $added');
        trace('  calculator.multiplyBy(25): $multiplied');
    }
}

// Helper enums for testing
enum Option<T> {
    Some(value: T);
    None;
}

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}