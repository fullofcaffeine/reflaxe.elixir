import js.lib.Promise;

/**
 * Complete test for async/await functionality with genes.
 * Uses clean @:async and @:await metadata syntax.
 */
@:build(genes.AsyncMacro.build())
class MainComplete {
    
    public static function main(): Void {
        // Test 1: Simple async function with inline metadata
        var simple = @:async function() {
            trace("Simple async function");
        };
        
        // Test 2: Async function with parameters
        var withParams = @:async function(name: String, age: Int) {
            trace('Hello $name, age $age');
        };
        
        // Test 3: Async function with await
        var withAwait = @:async function() {
            var result = @:await fetchData();
            trace('Got result: $result');
        };
        
        // Test 4: Async function with return value and await
        var withReturn = @:async function(): Promise<String> {
            var data = @:await fetchData();
            return Promise.resolve('Processed: $data');
        };
        
        // Test 5: Multiple awaits
        var multiAwait = @:async function() {
            var first = @:await fetchData();
            var second = @:await processData(first);
            trace('Results: $first, $second');
        };
        
        trace("All async functions created successfully");
    }
    
    static function fetchData(): Promise<String> {
        return Promise.resolve("Data from server");
    }
    
    static function processData(input: String): Promise<String> {
        return Promise.resolve('Processed: $input');
    }
}