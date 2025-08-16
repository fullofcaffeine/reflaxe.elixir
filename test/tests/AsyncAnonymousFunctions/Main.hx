import reflaxe.js.Async;
import js.lib.Promise;

using reflaxe.js.Async;

/**
 * Test @:async anonymous function support in JavaScript compilation.
 * This validates that the compiler correctly transforms various patterns.
 */
class Main {
    
    public static function main(): Void {
        // Test 1: Simple event handler with @:async
        addEventListener("click", @:async function(event) {
            var data = Async.Async.await(fetchData());
            processData(data);
        });
        
        // Test 2: Array map with @:async
        var urls = ["api/1", "api/2"];
        var promises = urls.map(@:async function(url) {
            var response = Async.await(fetch(url));
            return response.toUpperCase();
        });
        
        // Test 3: Variable assignment with @:async function
        var handler = @:async function(value: String): Promise<Int> {
            var result = Async.await(parseAsync(value));
            return result * 2;
        };
        
        // Test 4: Nested @:async functions
        var complex = @:async function(): Promise<String> {
            var inner = @:async function(x: Int): Promise<String> {
                var delayed = Async.await(Async.delay("result", x));
                return "Inner: " + delayed;
            };
            
            var result = Async.await(inner(100));
            return "Outer: " + result;
        };
        
        // Test 5: @:async in object literal
        var handlers = {
            onClick: @:async function(e): Promise<Void> {
                var target = Async.await(getTarget(e));
                updateUI(target);
            },
            
            onSubmit: @:async function(form): Promise<Bool> {
                var data = Async.await(validateForm(form));
                var success = Async.await(submitForm(data));
                return success;
            }
        };
        
        // Test 6: @:async function with multiple awaits
        var multiAwait = @:async function(): Promise<String> {
            var first = Async.await(step1());
            var second = Async.await(step2(first));
            var third = Async.await(step3(second));
            return third;
        };
        
        // Test 7: @:async function with error handling
        var errorHandler = @:async function(): Promise<String> {
            try {
                var risky = Async.await(riskyOperation());
                return "Success: " + risky;
            } catch (e: Dynamic) {
                return "Error: " + e;
            }
        };
        
        // Test 8: @:async function as callback
        setTimeout(@:async function() {
            var config = Async.await(loadConfig());
            initialize(config);
        }, 1000);
        
        // Test 9: Multiple @:async functions in array
        var asyncFunctions = [
            @:async function(): Promise<String> {
                return Async.await(Async.delay("first", 100));
            },
            @:async function(): Promise<String> {
                return Async.await(Async.delay("second", 200));
            }
        ];
        
        // Test 10: @:async arrow function style (if supported)
        var arrow = @:async function(x) return Async.await(Async.delay(x, 50));
    }
    
    // Helper functions for testing
    static function addEventListener(event: String, handler: Dynamic -> Void): Void {}
    static function fetchData(): Promise<String> return Async.resolve("data");
    static function processData(data: String): Void {}
    static function fetch(url: String): Promise<String> return Async.resolve("response");
    static function parseAsync(value: String): Promise<Int> return Async.resolve(42);
    static function getTarget(e: Dynamic): Promise<Dynamic> return Async.resolve({});
    static function updateUI(target: Dynamic): Void {}
    static function validateForm(form: Dynamic): Promise<Dynamic> return Async.resolve({});
    static function submitForm(data: Dynamic): Promise<Bool> return Async.resolve(true);
    static function step1(): Promise<String> return Async.resolve("step1");
    static function step2(input: String): Promise<String> return Async.resolve("step2");
    static function step3(input: String): Promise<String> return Async.resolve("step3");
    static function riskyOperation(): Promise<String> return Async.resolve("success");
    static function loadConfig(): Promise<Dynamic> return Async.resolve({});
    static function initialize(config: Dynamic): Void {}
    static function setTimeout(callback: Void -> Void, ms: Int): Void {}
}