package;

import reflaxe.js.Async;

/**
 * Test async/await JavaScript generation with AsyncJSGenerator.
 * 
 * This test validates that @:async functions generate proper
 * JavaScript async function declarations and await expressions.
 */
@:build(reflaxe.js.Async.build())
class Main {
    
    /**
     * Basic async function test.
     */
    @:async
    public static function simpleAsync(): js.lib.Promise<String> {
        var greeting = Async.await(js.lib.Promise.resolve("Hello"));
        return js.lib.Promise.resolve(greeting + " World");
    }
    
    /**
     * Multiple await expressions test.
     */
    @:async
    public static function multipleAwaits(): js.lib.Promise<String> {
        var first = Async.await(js.lib.Promise.resolve("First"));
        var second = Async.await(js.lib.Promise.resolve("Second"));
        var third = Async.await(js.lib.Promise.resolve("Third"));
        
        return js.lib.Promise.resolve(first + "-" + second + "-" + third);
    }
    
    /**
     * Error handling with try/catch test.
     */
    @:async
    public static function errorHandling(): js.lib.Promise<String> {
        try {
            var result = Async.await(js.lib.Promise.reject("Test Error"));
            return js.lib.Promise.resolve("Should not reach here");
        } catch (error: Dynamic) {
            return js.lib.Promise.resolve("Caught: " + error);
        }
    }
    
    /**
     * Conditional async operations test.
     */
    @:async
    public static function conditionalAsync(useAsync: Bool): js.lib.Promise<String> {
        if (useAsync) {
            var result = Async.await(js.lib.Promise.resolve("Async path"));
            return js.lib.Promise.resolve(result);
        } else {
            return js.lib.Promise.resolve("Sync path");
        }
    }
    
    /**
     * Regular function (should not have async keyword).
     */
    public static function regularFunction(): String {
        return "Not async";
    }
    
    /**
     * Static entry point (non-async).
     */
    public static function main(): Void {
        // Entry point for test compilation
    }
}