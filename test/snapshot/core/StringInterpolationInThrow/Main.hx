package;

/**
 * Test string interpolation in throw statements
 * 
 * This test ensures that complex string interpolation expressions
 * in throw statements are properly compiled to valid Elixir syntax.
 * 
 * The issue: String interpolation with conditionals was generating
 * invalid Elixir code with broken line continuations.
 */
class Main {
    static function main() {
        testSimpleInterpolation();
        testComplexConditional();
        testNestedFunctionCalls();
        testMultipleInterpolations();
        testNilHandling();
        testInRaise();
    }
    
    // Test 1: Simple string interpolation
    static function testSimpleInterpolation() {
        var errorCode = 404;
        try {
            throw 'Error code: ${errorCode}';
        } catch (e: String) {
            trace('Caught: $e');
        }
    }
    
    // Test 2: Complex conditional in interpolation (the main bug case)
    static function testComplexConditional() {
        var changeset = {errors: ["name is required", "email is invalid"]};
        try {
            var errors = getErrorsMap(changeset);
            throw 'Changeset has errors: ${errors != null ? errors.toString() : "null"}';
        } catch (e: String) {
            trace('Caught: $e');
        }
    }
    
    // Test 3: Nested function calls in interpolation
    static function testNestedFunctionCalls() {
        var data = {id: 123, name: "Test"};
        try {
            throw 'Failed to process: ${formatData(processData(data))}';
        } catch (e: String) {
            trace('Caught: $e');
        }
    }
    
    // Test 4: Multiple interpolations in one throw
    static function testMultipleInterpolations() {
        var user = "Alice";
        var action = "delete";
        var resource = "post";
        try {
            throw 'User ${user} cannot ${action} resource ${resource}';
        } catch (e: String) {
            trace('Caught: $e');
        }
    }
    
    // Test 5: Nil handling in interpolation
    static function testNilHandling() {
        var maybeValue: Null<String> = null;
        try {
            throw 'Value is: ${maybeValue == null ? "nil" : maybeValue}';
        } catch (e: String) {
            trace('Caught: $e');
        }
    }
    
    // Test 6: String interpolation in raise (different from throw)
    static function testInRaise() {
        var module = "UserController";
        var func = "show";
        try {
            // Using a custom exception type
            throw new CustomError('Error in ${module}.${func}');
        } catch (e: CustomError) {
            trace('Caught custom error: ${e.message}');
        }
    }
    
    // Helper functions
    static function getErrorsMap(changeset: Dynamic): Dynamic {
        return changeset.errors;
    }
    
    static function processData(data: Dynamic): Dynamic {
        return {processed: true, original: data};
    }
    
    static function formatData(data: Dynamic): String {
        return Std.string(data);
    }
}

// Custom exception class for testing
class CustomError {
    public var message: String;
    
    public function new(message: String) {
        this.message = message;
    }
}