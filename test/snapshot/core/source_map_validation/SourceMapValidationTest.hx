package;

/**
 * Integration test to validate source map structure and content.
 * Tests that:
 * 1. Source maps are generated with correct v3 format
 * 2. VLQ encoding produces non-empty mappings
 * 3. Sources array correctly references Haxe files
 * 4. File paths are properly resolved
 */
class SourceMapValidationTest {
    public static function main() {
        trace("=== Source Map Validation Test ===");
        
        // Test various code constructs to generate comprehensive mappings
        var simpleVar = "test";
        var number = 42;
        
        // Test function calls
        testFunction(simpleVar, number);
        
        // Test conditionals
        if (number > 0) {
            trace("Positive number");
        } else {
            trace("Non-positive number");
        }
        
        // Test loops
        for (i in 0...5) {
            trace('Loop iteration: $i');
        }
        
        // Test array operations
        var array = [1, 2, 3, 4, 5];
        for (item in array) {
            processItem(item);
        }
        
        // Test object creation
        var obj = {
            name: "Test",
            value: 100,
            nested: {
                field: "nested value"
            }
        };
        
        // Test class instantiation
        var instance = new TestClass("example");
        instance.doSomething();
        
        trace("=== Test Complete ===");
    }
    
    static function testFunction(str: String, num: Int): Void {
        trace('Testing with: $str and $num');
    }
    
    static function processItem(item: Int): Void {
        trace('Processing item: $item');
    }
}

class TestClass {
    private var name: String;
    
    public function new(name: String) {
        this.name = name;
    }
    
    public function doSomething(): Void {
        trace('TestClass doing something with: $name');
    }
}