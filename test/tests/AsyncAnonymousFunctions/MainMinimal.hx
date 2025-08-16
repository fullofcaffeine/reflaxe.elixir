import reflaxe.js.Async;
import js.lib.Promise;

/**
 * Minimal test to isolate the async transformation issue.
 */
class MainMinimal {
    
    public static function main(): Void {
        // Test without explicit return type first
        var simple = @:async function() {
            trace("hello");
        };
        
        trace("Anonymous async function created successfully");
    }
}