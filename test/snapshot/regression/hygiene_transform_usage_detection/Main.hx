/**
 * Test for hygiene transformation usage detection
 * 
 * CRITICAL: This test ensures that the hygiene transformation correctly detects
 * when parameters are actually used, even when nested in function calls.
 * 
 * Bug History:
 * - Initial implementation incorrectly marked `t` as unused in `Std.int(t)`
 * - The traversal wasn't recursing into function call arguments
 * - This caused compilation errors when `t` was renamed to `_t`
 */
class Main {
    static function main() {
        testNestedCallArgument();
        testDeepNesting();
        testMixedOperations();
        testWriteOnly();
        testShadowing();
        testFunctionParams();
        testForLoop();
        testStringConcatenation();
        testFieldVsIdent();
        testUnusedParameters();
    }
    
    // Test 1: Nested call argument (the original bug)
    static function fromTime(t: Float): Date {
        // `t` is used inside Std.int() - should NOT be prefixed with underscore
        return Date.fromUnix(Std.int(t), "millisecond");
    }
    
    // Test 2: Deep nesting chains
    static function deepNesting(t: Int): Int {
        // `t` is used deeply nested - should NOT be prefixed
        return Math.floor(Math.ceil(Math.abs(t)));
    }
    
    // Test 3: Mixed operations
    static function mixedOps(t: Int, u: Int): Int {
        // Both `t` and `u` are used - should NOT be prefixed
        if (t > 0) {
            trace(t);
            return t + u;
        }
        return u;
    }
    
    // Test 4: Write-only variable (should get underscore)
    static function writeOnly(input: Int): Int {
        var x = 0;  // Assigned but never read
        x = 2;      // Another write
        return input * 2;  // x is never used
    }
    
    // Test 5: Shadowing
    static function shadowing(): Int {
        var t = 1;  // Outer t - not used, should get underscore
        {
            var t = 2;  // Inner t - used
            return process(t);  // Uses inner t
        }
    }
    
    // Test 6: Function parameters - used vs unused
    static function usedParam(t: Int): Int {
        return t + 1;  // t is used - should NOT be prefixed
    }
    
    static function unusedParam(t: Int): Int {
        return 1;  // t is NOT used - SHOULD be prefixed with underscore
    }
    
    // Test 7: For loop
    static function forLoopTest(arr: Array<Int>): Int {
        var sum = 0;
        for (i in arr) {
            sum += i;  // i is used - should NOT be prefixed
        }
        return sum;
    }
    
    // Test 8: String concatenation (interpolation)
    static function stringConcat(t: String): String {
        return "Value: " + t;  // t is used - should NOT be prefixed
    }
    
    // Test 9: Field vs identifier
    static function fieldVsIdent(obj: Dynamic, t: Int): Void {
        obj.t = 1;  // This is NOT a use of parameter t
        trace(obj.t);  // This is also NOT a use of parameter t
        // Parameter t is unused - SHOULD be prefixed
    }
    
    // Test 10: Multiple unused parameters
    static function multipleUnused(a: Int, b: String, c: Float): Int {
        // None of the parameters are used - ALL should be prefixed
        return 42;
    }
    
    // Helper functions
    static function process(value: Int): Int {
        return value * 2;
    }
    
    static function testNestedCallArgument(): Void {
        var result = fromTime(1234567890.0);
        trace("Nested call test passed");
    }
    
    static function testDeepNesting(): Void {
        var result = deepNesting(-5);
        trace("Deep nesting test passed");
    }
    
    static function testMixedOperations(): Void {
        var result = mixedOps(5, 3);
        trace("Mixed operations test passed");
    }
    
    static function testWriteOnly(): Void {
        var result = writeOnly(10);
        trace("Write-only test passed");
    }
    
    static function testShadowing(): Void {
        var result = shadowing();
        trace("Shadowing test passed");
    }
    
    static function testFunctionParams(): Void {
        var r1 = usedParam(5);
        var r2 = unusedParam(5);
        trace("Function params test passed");
    }
    
    static function testForLoop(): Void {
        var result = forLoopTest([1, 2, 3]);
        trace("For loop test passed");
    }
    
    static function testStringConcatenation(): Void {
        var result = stringConcat("test");
        trace("String concatenation test passed");
    }
    
    static function testFieldVsIdent(): Void {
        fieldVsIdent({}, 5);
        trace("Field vs ident test passed");
    }
    
    static function testUnusedParameters(): Void {
        var result = multipleUnused(1, "test", 3.14);
        trace("Multiple unused test passed");
    }
}

// Mock Date class for testing
class Date {
    public static function fromUnix(timestamp: Int, unit: String): Date {
        return new Date();
    }
    
    public function new() {}
}