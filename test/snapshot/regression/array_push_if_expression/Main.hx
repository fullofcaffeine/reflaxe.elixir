/**
 * Test: Array push operations in if expressions
 * 
 * Issue: In Elixir, variable assignments inside if expressions create local bindings
 * that don't affect the outer scope. This test ensures array.push() in if expressions
 * properly updates the outer array variable.
 * 
 * Expected behavior:
 * - Array.push() in if true branch should add to array
 * - Array.push() in if false branch should be skipped
 * - Final array should contain pushed values
 */
class Main {
    public static function main() {
        testSimpleIfPush();
        testIfElsePush();
        testConditionalAccumulation();
        testNestedIfPush();
    }
    
    static function testSimpleIfPush() {
        var errors = [];
        var hasError = true;
        
        // This should push to errors array
        if (hasError) {
            errors.push("Error occurred");
        }
        
        trace('Simple if push result: ${errors}'); // Should contain ["Error occurred"]
    }
    
    static function testIfElsePush() {
        var messages = [];
        var success = false;
        
        if (success) {
            messages.push("Success!");
        } else {
            messages.push("Failed!");
        }
        
        trace('If-else push result: ${messages}'); // Should contain ["Failed!"]
    }
    
    static function testConditionalAccumulation() {
        var errors = [];
        
        // Multiple conditional pushes
        if (true) errors.push("Error 1");
        if (false) errors.push("Error 2"); // Should not be added
        if (true) errors.push("Error 3");
        
        trace('Conditional accumulation: ${errors}'); // Should contain ["Error 1", "Error 3"]
    }
    
    static function testNestedIfPush() {
        var results = [];
        var level1 = true;
        var level2 = true;
        
        if (level1) {
            results.push("Level 1");
            if (level2) {
                results.push("Level 2");
            }
        }
        
        trace('Nested if push: ${results}'); // Should contain ["Level 1", "Level 2"]
    }
}