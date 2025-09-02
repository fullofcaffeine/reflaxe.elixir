package;

import js.lib.Promise;

/**
 * Test async/await JavaScript generation with genes.
 * 
 * This test validates that @:async functions generate proper
 * JavaScript async function declarations and @:await expressions
 * work correctly with the genes ES6 generator.
 */
@:build(genes.AsyncMacro.build())
class Main {
    
    /**
     * Basic async function test.
     */
    @:async
    public static function simpleAsync(): Promise<String> {
        var greeting = @:await Promise.resolve("Hello");
        return Promise.resolve(greeting + " World");
    }
    
    /**
     * Multiple await expressions test.
     */
    @:async
    public static function multipleAwaits(): Promise<String> {
        var first = @:await Promise.resolve("First");
        var second = @:await Promise.resolve("Second");
        var third = @:await Promise.resolve("Third");
        
        return Promise.resolve(first + "-" + second + "-" + third);
    }
    
    /**
     * Error handling with try/catch test.
     */
    @:async
    public static function errorHandling(): Promise<String> {
        try {
            var result = @:await Promise.reject("Test Error");
            return Promise.resolve("Should not reach here");
        } catch (error: Dynamic) {
            return Promise.resolve("Caught: " + error);
        }
    }
    
    /**
     * Conditional async operations test.
     */
    @:async
    public static function conditionalAsync(useAsync: Bool): Promise<String> {
        if (useAsync) {
            var result = @:await Promise.resolve("Async path");
            return Promise.resolve(result);
        } else {
            return Promise.resolve("Sync path");
        }
    }
    
    /**
     * Test nested try/catch with different error types.
     */
    @:async
    public static function nestedErrorHandling(): Promise<String> {
        try {
            try {
                @:await Promise.reject({code: 404, message: "Not found"});
                return Promise.resolve("Should not reach");
            } catch (e: Dynamic) {
                // Re-throw with modification
                throw 'Wrapped: ${e.message}';
            }
        } catch (e: String) {
            return Promise.resolve('Caught string: $e');
        }
    }
    
    /**
     * Test that async functions enforce Promise<T> return type.
     */
    @:async
    public static function typeEnforcementTest(): Promise<Int> {
        var value = @:await Promise.resolve(42);
        // Must return Promise<Int>, not just Int
        return Promise.resolve(value * 2);
    }
    
    /**
     * Test Promise<T> type unwrapping with await.
     */
    @:async
    public static function typeUnwrappingTest(): Promise<Bool> {
        // Promise<String> unwraps to String
        var str = @:await Promise.resolve("test");
        // Promise<Int> unwraps to Int
        var num = @:await Promise.resolve(42);
        // Type checking works - can call String methods on str
        var result = str.length == 4 && num == 42;
        return Promise.resolve(result);
    }
    
    /**
     * Test try/catch with finally simulation (Haxe doesn't have finally).
     */
    @:async
    public static function finallySimulation(): Promise<String> {
        var cleanup = false;
        try {
            @:await Promise.resolve("success");
            cleanup = true;
            return Promise.resolve("Success");
        } catch (e: Dynamic) {
            cleanup = true;
            return Promise.resolve('Error: $e');
        }
        // cleanup is guaranteed to be set
    }
    
    /**
     * Inline async function test with @:async metadata.
     */
    public static function inlineAsyncTest(): Void {
        // Test inline async function syntax
        var fetchData = @:async function(): Promise<String> {
            var data = @:await Promise.resolve("Inline async data");
            return Promise.resolve("Fetched: " + data);
        };
        
        // Test with parameters and error handling
        var processData = @:async function(input: String): Promise<String> {
            try {
                if (input == "error") {
                    @:await Promise.reject("Invalid input");
                }
                var processed = @:await Promise.resolve(input.toUpperCase());
                return Promise.resolve("Processed: " + processed);
            } catch (e: Dynamic) {
                return Promise.resolve('Error processing: $e');
            }
        };
        
        // Test inline async with specific return type
        var computeValue = @:async function(x: Int, y: Int): Promise<Int> {
            var sum = @:await Promise.resolve(x + y);
            return Promise.resolve(sum * 2);
        };
    }
    
    /**
     * Regular function (should not have async keyword).
     */
    public static function regularFunction(): String {
        return "Not async";
    }
    
    /**
     * Simple assertion helper.
     */
    static function assert(condition: Bool, message: String): Void {
        if (!condition) {
            throw 'Assertion failed: $message';
        }
        trace('✓ $message');
    }
    
    /**
     * Async assertion helper.
     */
    @:async
    static function runTests(): Promise<Void> {
        trace("Running async/await tests...");
        
        // Test 1: Basic async/await
        var result1 = @:await simpleAsync();
        assert(result1 == "Hello World", "Basic async function returns correct value");
        
        // Test 2: Multiple awaits
        var result2 = @:await multipleAwaits();
        assert(result2 == "First-Second-Third", "Multiple awaits work correctly");
        
        // Test 3: Error handling
        var result3 = @:await errorHandling();
        assert(result3 == "Caught: Test Error", "Error handling catches rejections");
        
        // Test 4: Conditional async
        var result4a = @:await conditionalAsync(true);
        assert(result4a == "Async path", "Conditional async with true");
        var result4b = @:await conditionalAsync(false);
        assert(result4b == "Sync path", "Conditional async with false");
        
        // Test 5: Nested error handling
        var result5 = @:await nestedErrorHandling();
        assert(result5.indexOf("Wrapped:") >= 0, "Nested error handling works");
        
        // Test 6: Type enforcement (value * 2)
        var result6 = @:await typeEnforcementTest();
        assert(result6 == 84, "Type enforcement returns correct Int");
        
        // Test 7: Type unwrapping
        var result7 = @:await typeUnwrappingTest();
        assert(result7 == true, "Type unwrapping preserves types correctly");
        
        // Test 8: Finally simulation
        var result8 = @:await finallySimulation();
        assert(result8 == "Success", "Finally simulation completes successfully");
        
        trace("All tests passed!");
        return Promise.resolve();
    }
    
    /**
     * Static entry point (non-async).
     */
    public static function main(): Void {
        // Run inline tests
        inlineAsyncTest();
        
        // Run async tests with assertions
        runTests().then(
            _ -> trace("Test suite completed successfully"),
            error -> trace('Test suite failed: $error')
        );
    }
}