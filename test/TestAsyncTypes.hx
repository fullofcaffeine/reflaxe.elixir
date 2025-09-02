import js.lib.Promise;

/**
 * Test to verify that async/await respects Promise types correctly
 * and handles errors properly like native JavaScript.
 */
@:build(genes.AsyncMacro.build())
class TestAsyncTypes {
    
    // Test 1: Type inference with await
    @:async
    static function testTypeInference(): Promise<Int> {
        // This should infer greeting as String
        var greeting = @:await Promise.resolve("Hello");
        
        // This should infer count as Int
        var count = @:await Promise.resolve(42);
        
        // This should work because count is Int
        return Promise.resolve(count + 1);
    }
    
    // Test 2: Generic Promise types
    @:async
    static function testGenericPromise<T>(value: T): Promise<T> {
        var result = @:await Promise.resolve(value);
        return Promise.resolve(result);
    }
    
    // Test 3: Nested Promise unwrapping
    @:async
    static function testNestedPromises(): Promise<String> {
        // Promise<Promise<String>> should unwrap to String
        var nested = Promise.resolve(Promise.resolve("nested"));
        var result = @:await nested;  // Should be Promise<String>
        var unwrapped = @:await result;   // Should be String
        return Promise.resolve(unwrapped.toUpperCase());
    }
    
    // Test 4: Array of Promises with Promise.all
    @:async
    static function testPromiseArray(): Promise<Array<Int>> {
        var promises = [
            Promise.resolve(1),
            Promise.resolve(2),
            Promise.resolve(3)
        ];
        
        // Promise.all should return Promise<Array<Int>>
        var results = @:await Promise.all(promises);
        return Promise.resolve(results);
    }
    
    // Test 5: Basic error handling with try/catch
    @:async
    static function testBasicErrorHandling(): Promise<String> {
        try {
            var result = @:await Promise.reject("Error message");
            return Promise.resolve("Should not reach here");
        } catch (error: Dynamic) {
            // Should catch the rejection
            return Promise.resolve('Caught: $error');
        }
    }
    
    // Test 6: Error propagation in async functions
    @:async
    static function testErrorPropagation(): Promise<String> {
        // This should propagate the error up
        var result = @:await failingAsyncFunction();
        return Promise.resolve(result);
    }
    
    @:async
    static function failingAsyncFunction(): Promise<String> {
        throw "Async function error";
        return Promise.resolve("Never reached");
    }
    
    // Test 7: Multiple error handling scenarios
    @:async
    static function testComplexErrorHandling(): Promise<String> {
        var results = [];
        
        // Test 1: Catch specific error
        try {
            @:await Promise.reject("First error");
        } catch (e: String) {
            results.push('String error: $e');
        }
        
        // Test 2: Catch and rethrow
        try {
            try {
                @:await Promise.reject({code: 404, message: "Not found"});
            } catch (e: Dynamic) {
                // Transform and rethrow
                throw 'Transformed: ${e.message}';
            }
        } catch (e: String) {
            results.push(e);
        }
        
        // Test 3: Simulated finally behavior (Haxe doesn't have finally)
        var finallyCalled = false;
        try {
            @:await Promise.resolve("Success");
            finallyCalled = true;
        } catch (e: Dynamic) {
            results.push("Should not be here");
            finallyCalled = true;
        }
        
        if (finallyCalled) {
            results.push("Finally simulation worked");
        }
        
        return Promise.resolve(results.join(", "));
    }
    
    // Test 8: Async functions require explicit Promise.resolve
    @:async
    static function testExplicitReturn(): Promise<Int> {
        var value = @:await Promise.resolve(10);
        // Unlike JavaScript, Haxe requires explicit Promise wrapping
        // This maintains type safety and makes the code more explicit
        return Promise.resolve(value * 2);
    }
    
    // Test 9: Promise.race with type safety
    @:async
    static function testPromiseRace(): Promise<String> {
        var slow = new Promise<String>((resolve, reject) -> {
            // Simulated slow promise
            haxe.Timer.delay(() -> resolve("slow"), 100);
        });
        
        var fast = Promise.resolve("fast");
        
        var winner = @:await Promise.race([slow, fast]);
        return Promise.resolve(winner);
    }
    
    // Test 10: Chaining with then/catchError (traditional Promise style)
    static function testPromiseChaining(): Promise<String> {
        return Promise.resolve(42)
            .then(num -> Promise.resolve('Number: $num'))
            .then(str -> Promise.resolve(str.toUpperCase()))
            .catchError(err -> Promise.resolve('Error: $err'));
    }
    
    // Test 11: Mixed async/await and Promise chaining
    @:async
    static function testMixedStyles(): Promise<String> {
        var result = @:await Promise.resolve("start")
            .then(s -> Promise.resolve(s + " middle"))
            .then(s -> Promise.resolve(s + " end"));
        
        return Promise.resolve(result.toUpperCase());
    }
    
    // Test 12: Error types preservation
    @:async
    static function testErrorTypes(): Promise<String> {
        try {
            @:await Promise.reject(new js.lib.Error("JavaScript Error"));
        } catch (e: js.lib.Error) {
            // Should catch as JavaScript Error type
            return Promise.resolve('JS Error: ${e.message}');
        } catch (e: Dynamic) {
            return Promise.resolve('Unknown error: $e');
        }
    }
    
    static function main() {
        // Run all tests
        testBasicErrorHandling().then(
            result -> trace('Basic error handling: $result'),
            error -> trace('Test failed: $error')
        );
        
        testComplexErrorHandling().then(
            result -> trace('Complex error handling: $result'),
            error -> trace('Test failed: $error')
        );
        
        testErrorPropagation().then(
            result -> trace('Should not succeed: $result'),
            error -> trace('Error propagation worked: $error')
        );
    }
}