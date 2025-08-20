package;

import haxe.format.JsonPrinter;

/**
 * Test for JsonPrinter temp variable scoping issue
 * 
 * This test reproduces the issue where temp variables are assigned inside
 * if expressions, creating local scope that makes them inaccessible outside.
 * 
 * Pattern: if (cond), do: temp_var = val1, else: temp_var = val2
 * Issue: temp_var is not accessible after the if expression
 * Fix: Should generate: var = if (cond), do: val1, else: val2
 */
class Main {
    public static function testTempVariableScoping(): Void {
        // JsonPrinter.print is a static method, no need to instantiate
        // This will create a ternary that assigns to temp variables
        
        // Test with a number that triggers the Math.isFinite path
        var obj = {
            finiteNumber: 42.5,
            infiniteNumber: Math.POSITIVE_INFINITY,
            stringValue: "test"
        };
        
        // This should compile without temp variable scope errors
        var result = JsonPrinter.print(obj, null, null);
        
        trace('Serialized JSON: $result');
    }
    
    public static function testTernaryWithTempVars(): Void {
        // Simulate the pattern that causes temp variable issues
        var value = 42.5;
        
        // This creates: if (condition), do: temp_var = val1, else: temp_var = val2
        // Followed by: result = temp_var (which should fail in current implementation)
        var result = Math.isFinite(value) ? Std.string(value) : "null";
        
        trace('Ternary result: $result');
    }
    
    public static function main() {
        trace("=== Testing JsonPrinter Temp Variable Scoping ===");
        testTempVariableScoping();
        
        trace("\n=== Testing Ternary with Temp Variables ===");
        testTernaryWithTempVars();
    }
}