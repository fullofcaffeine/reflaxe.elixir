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
     * Inline async function test with @:async metadata.
     */
    public static function inlineAsyncTest(): Void {
        // Test inline async function syntax
        var fetchData = @:async function(): Promise<String> {
            var data = @:await Promise.resolve("Inline async data");
            return Promise.resolve("Fetched: " + data);
        };
        
        // Test with parameters
        var processData = @:async function(input: String): Promise<String> {
            var processed = @:await Promise.resolve(input.toUpperCase());
            return Promise.resolve("Processed: " + processed);
        };
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
        inlineAsyncTest();
    }
}