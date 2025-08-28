import reflaxe.js.Async;
import js.lib.Promise;

/**
 * Simple test to debug @:async anonymous function transformation.
 */
class MainSimple {
    
    public static function main(): Void {
        trace("Testing basic async transformation");
        
        // Test 1: Just a simple @:async function without await
        var simple = @:async function(): Promise<String> {
            return "hello";
        };
        
        // Test 2: Regular class method for comparison
        testClassMethod();
    }
    
    @:async
    public static function testClassMethod(): Promise<String> {
        return "class method";
    }
}