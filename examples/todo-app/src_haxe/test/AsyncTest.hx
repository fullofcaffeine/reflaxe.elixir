package test;

import reflaxe.js.Async;

/**
 * Test class for async/await functionality.
 * 
 * Demonstrates the new @:async syntax and await() macro usage
 * with type-safe Promise handling.
 */
@:build(reflaxe.js.Async.build())
class AsyncTest {
    
    /**
     * Test basic async function with await.
     * 
     * This function should compile to:
     * ```javascript
     * async function testBasicAsync() {
     *     var result = await Promise.resolve("Hello");
     *     return result + " World";
     * }
     * ```
     */
    @:async
    public static function testBasicAsync(): js.lib.Promise<String> {
        var result = Async.await(js.lib.Promise.resolve("Hello"));
        return js.lib.Promise.resolve(result + " World");
    }
    
    /**
     * Test async function with multiple awaits.
     * 
     * Demonstrates sequential async operations with proper type inference.
     */
    @:async
    public static function testMultipleAwaits(): js.lib.Promise<String> {
        var greeting = Async.await(js.lib.Promise.resolve("Hello"));
        var target = Async.await(js.lib.Promise.resolve("Phoenix"));
        var punctuation = Async.await(js.lib.Promise.resolve("!"));
        
        return js.lib.Promise.resolve(greeting + " " + target + punctuation);
    }
    
    /**
     * Test async function with error handling.
     * 
     * Uses try/catch with async/await for proper error propagation.
     */
    @:async
    public static function testErrorHandling(): js.lib.Promise<String> {
        try {
            var result = Async.await(js.lib.Promise.reject("Error occurred"));
            return js.lib.Promise.resolve(result);
        } catch (error: Dynamic) {
            return js.lib.Promise.resolve("Caught: " + error);
        }
    }
    
    /**
     * Test async function with conditional await.
     * 
     * Demonstrates await usage in conditional expressions.
     */
    @:async
    public static function testConditionalAwait(useAsync: Bool): js.lib.Promise<String> {
        if (useAsync) {
            var result = Async.await(js.lib.Promise.resolve("Async result"));
            return js.lib.Promise.resolve(result);
        } else {
            return js.lib.Promise.resolve("Sync result");
        }
    }
    
    /**
     * Helper function that returns a Promise for testing.
     */
    public static function createDelayedPromise(value: String, delayMs: Int): js.lib.Promise<String> {
        return new js.lib.Promise(function(resolve, reject) {
            js.Browser.window.setTimeout(function() {
                resolve(value);
            }, delayMs);
        });
    }
    
    /**
     * Test async function with delayed operations.
     * 
     * Demonstrates real-world async patterns with delays.
     */
    @:async
    public static function testDelayedOperations(): js.lib.Promise<String> {
        var first = Async.await(createDelayedPromise("First", 100));
        var second = Async.await(createDelayedPromise("Second", 50));
        var third = Async.await(createDelayedPromise("Third", 25));
        
        return js.lib.Promise.resolve(first + " -> " + second + " -> " + third);
    }
    
    /**
     * Entry point for testing async functionality.
     * 
     * This function can be called from PhoenixApp to verify
     * that async/await compilation works correctly.
     */
    public static function main(): Void {
        js.Browser.console.log("🧪 Starting async/await tests...");
        runTests();
    }
    
    /**
     * Runs all async/await tests.
     * 
     * This function can be called from PhoenixApp to verify
     * that async/await compilation works correctly.
     */
    public static function runTests(): js.lib.Promise<String> {
        js.Browser.console.log("🧪 Running async/await tests...");
        
        // Test basic async functionality
        return testBasicAsync().then(function(result) {
            js.Browser.console.log("✅ Basic async test:", result);
            return testMultipleAwaits();
        }).then(function(result) {
            js.Browser.console.log("✅ Multiple awaits test:", result);
            return testErrorHandling();
        }).then(function(result) {
            js.Browser.console.log("✅ Error handling test:", result);
            return testConditionalAwait(true);
        }).then(function(result) {
            js.Browser.console.log("✅ Conditional await test:", result);
            return testDelayedOperations();
        }).then(function(result) {
            js.Browser.console.log("✅ Delayed operations test:", result);
            js.Browser.console.log("🎉 All async/await tests completed successfully!");
            return "All tests passed";
        }).catchError(function(error) {
            js.Browser.console.error("❌ Async test failed:", error);
            return "Tests failed: " + error;
        });
    }
}