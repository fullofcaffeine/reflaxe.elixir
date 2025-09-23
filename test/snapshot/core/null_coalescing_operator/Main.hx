/**
 * Test null coalescing operator (??) in various contexts
 * 
 * This test ensures the null coalescing operator compiles to valid inline
 * Elixir expressions in all contexts, especially inside object/map literals.
 */
class Main {
    static function main() {
        // Test 1: Simple variable assignment
        testSimpleAssignment();
        
        // Test 2: Inside function arguments
        testFunctionArguments();
        
        // Test 3: Inside object literals (the problematic case)
        testObjectLiterals();
        
        // Test 4: Inside array literals
        testArrayLiterals();
        
        // Test 5: Nested null coalescing
        testNestedCoalescing();
        
        // Test 6: With method calls
        testMethodCalls();
    }
    
    static function testSimpleAssignment() {
        var maybeNull: Null<String> = null;
        var notNull: String = "value";
        
        // Simple null coalescing
        var result1 = maybeNull ?? "default";
        var result2 = notNull ?? "default";
        
        // With intermediate variables
        var intermediate = getValue();
        var result3 = intermediate ?? "fallback";
    }
    
    static function testFunctionArguments() {
        var optional: Null<String> = null;
        
        // Null coalescing in function arguments
        doSomething(optional ?? "default");
        doMultiple(optional ?? "first", getValue() ?? "second");
    }
    
    static function testObjectLiterals() {
        var optional: Null<String> = null;
        var maybeInt: Null<Int> = null;
        var maybeBool: Null<Bool> = null;
        
        // This is the problematic case - null coalescing inside object literals
        var obj = {
            name: optional ?? "defaultName",
            count: maybeInt ?? 0,
            enabled: maybeBool ?? true,
            nested: {
                value: optional ?? "nestedDefault",
                flag: maybeBool ?? false
            }
        };
        
        // With field access
        var data = getData();
        var obj2 = {
            title: data.title ?? "Untitled",
            description: data.description ?? "No description",
            active: data.active ?? true
        };
    }
    
    static function testArrayLiterals() {
        var maybe1: Null<String> = null;
        var maybe2: Null<String> = null;
        
        // Null coalescing in array literals
        var arr = [
            maybe1 ?? "item1",
            getValue() ?? "item2",
            maybe2 ?? "item3"
        ];
    }
    
    static function testNestedCoalescing() {
        var first: Null<String> = null;
        var second: Null<String> = null;
        var third: String = "final";
        
        // Chained null coalescing
        var result = first ?? second ?? third;
        
        // Nested in expressions
        var complex = (first ?? "a") + (second ?? "b");
    }
    
    static function testMethodCalls() {
        var obj: Null<TestObject> = null;
        
        // Null coalescing with method calls
        var name = (obj != null ? obj.getName() : null) ?? "Anonymous";
        var value = (obj != null ? obj.getValue() : null) ?? 100;
        
        // With chain
        var opt = getOptional();
        var result = (opt != null ? opt.process() : null) ?? "default";
    }
    
    // Helper functions
    static function getValue(): Null<String> {
        return null;
    }
    
    static function getData(): Dynamic {
        return {
            title: null,
            description: "Has value",
            active: null
        };
    }
    
    static function doSomething(value: String): Void {}
    
    static function doMultiple(a: String, b: String): Void {}
    
    static function getOptional(): Null<TestObject> {
        return null;
    }
}

class TestObject {
    public function new() {}
    
    public function getName(): String {
        return "TestName";
    }
    
    public function getValue(): Int {
        return 42;
    }
    
    public function process(): String {
        return "processed";
    }
}