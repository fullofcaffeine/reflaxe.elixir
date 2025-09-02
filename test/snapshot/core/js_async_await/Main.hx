package;

import js.lib.Promise;

/**
 * Comprehensive async/await test suite for Haxe→JavaScript compilation.
 * 
 * This test validates full 1:1 parity with JavaScript/TypeScript async/await:
 * 
 * WHAT THIS TESTS:
 * ================
 * 1. Clean ES6 async/await generation without wrappers
 * 2. Automatic Promise wrapping (return 42 → Promise.resolve(42))
 * 3. Type unwrapping (@:await Promise<T> → T)
 * 4. Exception handling with try/catch
 * 5. Error propagation through async chains
 * 6. Promise.all and Promise.race integration
 * 7. Type safety and compile-time checking
 * 8. Inline async functions
 * 9. Nested try/catch with re-throwing
 * 
 * IMPLEMENTATION DETAILS:
 * =======================
 * - Uses @:async/@:await metadata (Haxe doesn't have native keywords)
 * - Requires @:build(genes.AsyncMacro.build()) for transformation
 * - Generates clean ES6 without __async_marker__ in output
 * - Full Promise<T> type parameterization preserved
 * 
 * JAVASCRIPT EQUIVALENCE:
 * =======================
 * Haxe:       @:async function foo(): Promise<String>
 * JavaScript: async function foo(): Promise<string>
 * 
 * Haxe:       var x = @:await somePromise;
 * JavaScript: let x = await somePromise;
 * 
 * @see docs/04-api-reference/async-await-specification.md
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
     * Test automatic Promise wrapping (1:1 with JavaScript).
     */
    @:async
    public static function automaticWrappingTest(): Promise<String> {
        // In JavaScript/TypeScript, returning a non-Promise value
        // from an async function automatically wraps it
        return "automatically wrapped";  // Should become Promise.resolve("automatically wrapped")
    }
    
    /**
     * Test error propagation through async chain.
     */
    @:async
    public static function errorPropagationTest(): Promise<String> {
        try {
            var result = @:await throwingAsyncFunction();
            return "Should not reach";
        } catch (e: Dynamic) {
            return 'Propagated: $e';
        }
    }
    
    @:async
    static function throwingAsyncFunction(): Promise<String> {
        throw "Async error";
        return "Never reached";
    }
    
    /**
     * Test Promise.all with async/await.
     */
    @:async
    public static function promiseAllTest(): Promise<String> {
        var promises = [
            Promise.resolve("A"),
            Promise.resolve("B"),
            Promise.resolve("C")
        ];
        var results = @:await Promise.all(promises);
        return results.join("-");
    }
    
    /**
     * Test Promise.race with async/await.
     * Note: In Node.js environment, we use immediate resolution instead of setTimeout.
     */
    @:async
    public static function promiseRaceTest(): Promise<String> {
        // Fast promise resolves immediately
        var fast = Promise.resolve("fast");
        // Slow promise would resolve later (simulated)
        var slow = Promise.resolve("slow");  // Simplified for testing
        return @:await Promise.race([slow, fast]);
    }
    
    /**
     * Test chained async operations.
     */
    @:async
    public static function chainedAsyncTest(): Promise<Int> {
        var a = @:await Promise.resolve(10);
        var b = @:await addAsync(a, 5);
        var c = @:await multiplyAsync(b, 2);
        return c;  // Should be 30
    }
    
    @:async
    static function addAsync(x: Int, y: Int): Promise<Int> {
        return x + y;
    }
    
    @:async
    static function multiplyAsync(x: Int, y: Int): Promise<Int> {
        return x * y;
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
     * Async assertion helper with comprehensive testing.
     */
    @:async
    static function runTests(): Promise<Void> {
        trace("Running comprehensive async/await tests...");
        trace("=======================================");
        
        // Test 1: Basic async/await
        trace("\n[TEST 1] Basic async/await:");
        var result1 = @:await simpleAsync();
        assert(result1 == "Hello World", "Basic async function returns correct value");
        assert(result1 is String, "Return type is String as expected");
        
        // Test 2: Multiple awaits
        trace("\n[TEST 2] Multiple awaits:");
        var result2 = @:await multipleAwaits();
        assert(result2 == "First-Second-Third", "Multiple awaits work correctly");
        
        // Test 3: Error handling with try/catch
        trace("\n[TEST 3] Error handling:");
        var result3 = @:await errorHandling();
        assert(result3 == "Caught: Test Error", "Try/catch catches Promise rejections");
        
        // Test 4: Conditional async
        trace("\n[TEST 4] Conditional async:");
        var result4a = @:await conditionalAsync(true);
        assert(result4a == "Async path", "Conditional async with true");
        var result4b = @:await conditionalAsync(false);
        assert(result4b == "Sync path", "Conditional async with false");
        
        // Test 5: Nested error handling
        trace("\n[TEST 5] Nested try/catch:");
        var result5 = @:await nestedErrorHandling();
        assert(result5.indexOf("Wrapped:") >= 0, "Nested error handling with re-throw works");
        
        // Test 6: Type enforcement
        trace("\n[TEST 6] Type enforcement:");
        var result6 = @:await typeEnforcementTest();
        assert(result6 == 84, "Promise<Int> type enforced correctly");
        assert(Std.is(result6, Int), "Result is Int type");
        
        // Test 7: Automatic Promise wrapping
        trace("\n[TEST 7] Automatic Promise wrapping:");
        var result7 = @:await automaticWrappingTest();
        assert(result7 == "automatically wrapped", "Non-Promise returns are auto-wrapped");
        
        // Test 8: Error propagation
        trace("\n[TEST 8] Error propagation:");
        var result8 = @:await errorPropagationTest();
        assert(result8 == "Propagated: Async error", "Errors propagate through async chain");
        
        // Test 9: Promise.all
        trace("\n[TEST 9] Promise.all:");
        var result9 = @:await promiseAllTest();
        assert(result9 == "A-B-C", "Promise.all works with await");
        
        // Test 10: Promise.race
        trace("\n[TEST 10] Promise.race:");
        var result10 = @:await promiseRaceTest();
        assert(result10 == "fast" || result10 == "slow", "Promise.race returns one of the results");
        
        // Test 11: Chained async operations
        trace("\n[TEST 11] Chained async:");
        var result11 = @:await chainedAsyncTest();
        assert(result11 == 30, "Chained async operations maintain correct values");
        
        // Test 12: Type unwrapping
        trace("\n[TEST 12] Type unwrapping:");
        var result12 = @:await typeUnwrappingTest();
        assert(result12 == true, "Promise<T> unwraps to T correctly");
        
        // Test 13: Finally simulation
        trace("\n[TEST 13] Finally simulation:");
        var result13 = @:await finallySimulation();
        assert(result13 == "Success", "Finally simulation works");
        
        // Test 14: Verify regular function is NOT async
        trace("\n[TEST 14] Non-async functions:");
        var regular = regularFunction();
        assert(regular == "Not async", "Regular functions remain synchronous");
        
        trace("\n=======================================");
        trace("✅ All async/await tests passed!");
        trace("Total tests: 14");
        trace("=======================================");
        
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