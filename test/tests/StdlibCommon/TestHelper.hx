package;

/**
 * Shared test infrastructure for standard library tests
 * 
 * Provides DRY utilities for testing that stdlib modules:
 * 1. Compile correctly
 * 2. Generate idiomatic Elixir
 * 3. Behave as expected at runtime
 */
class TestHelper {
    /**
     * Asserts that two values are equal
     * Traces error message if not equal
     */
    public static function assertEquals<T>(expected: T, actual: T, ?message: String) {
        if (expected != actual) {
            var msg = message != null ? message : "Assertion failed";
            trace('$msg: Expected $expected but got $actual');
            throw 'Test failed: $msg';
        }
    }
    
    /**
     * Asserts that a value is true
     */
    public static function assertTrue(value: Bool, ?message: String) {
        if (!value) {
            var msg = message != null ? message : "Expected true";
            trace('$msg');
            throw 'Test failed: $msg';
        }
    }
    
    /**
     * Asserts that a value is false
     */
    public static function assertFalse(value: Bool, ?message: String) {
        if (value) {
            var msg = message != null ? message : "Expected false";
            trace('$msg');
            throw 'Test failed: $msg';
        }
    }
    
    /**
     * Asserts that a value is null
     */
    public static function assertNull<T>(value: Null<T>, ?message: String) {
        if (value != null) {
            var msg = message != null ? message : "Expected null";
            trace('$msg: Got $value');
            throw 'Test failed: $msg';
        }
    }
    
    /**
     * Asserts that a value is not null
     */
    public static function assertNotNull<T>(value: Null<T>, ?message: String) {
        if (value == null) {
            var msg = message != null ? message : "Expected non-null value";
            trace('$msg');
            throw 'Test failed: $msg';
        }
    }
    
    /**
     * Asserts that an array contains expected elements
     */
    public static function assertArrayEquals<T>(expected: Array<T>, actual: Array<T>, ?message: String) {
        if (expected.length != actual.length) {
            var msg = message != null ? message : "Array length mismatch";
            trace('$msg: Expected length ${expected.length} but got ${actual.length}');
            throw 'Test failed: $msg';
        }
        
        for (i in 0...expected.length) {
            if (expected[i] != actual[i]) {
                var msg = message != null ? message : "Array element mismatch";
                trace('$msg at index $i: Expected ${expected[i]} but got ${actual[i]}');
                throw 'Test failed: $msg';
            }
        }
    }
    
    /**
     * Runs a test case and reports results
     * 
     * Usage:
     * ```haxe
     * TestHelper.runTest("StringBuf basic usage", function() {
     *     var buf = new StringBuf();
     *     buf.add("Hello");
     *     TestHelper.assertEquals("Hello", buf.toString());
     * });
     * ```
     */
    public static function runTest(name: String, testFunc: Void -> Void) {
        trace('Running test: $name');
        try {
            testFunc();
            trace('✓ $name passed');
        } catch (e: Dynamic) {
            trace('✗ $name failed: $e');
            throw e;
        }
    }
    
    /**
     * Runs a suite of tests
     * 
     * Usage:
     * ```haxe
     * TestHelper.runSuite("StringBuf Tests", [
     *     "basic usage" => testBasicUsage,
     *     "null handling" => testNullHandling,
     *     "large strings" => testLargeStrings
     * ]);
     * ```
     */
    public static function runSuite(suiteName: String, tests: Map<String, Void -> Void>) {
        trace('');
        trace('=== $suiteName ===');
        var passed = 0;
        var failed = 0;
        
        for (name => test in tests) {
            try {
                runTest(name, test);
                passed++;
            } catch (e: Dynamic) {
                failed++;
            }
        }
        
        trace('');
        trace('Results: $passed passed, $failed failed');
        if (failed > 0) {
            throw 'Test suite failed with $failed failures';
        }
    }
    
    /**
     * Helper to document expected Elixir output
     * This doesn't affect runtime but helps document what code should generate
     * 
     * Usage:
     * ```haxe
     * TestHelper.expectsElixir(
     *     "StringBuf.new()",
     *     "iolist = []"
     * );
     * ```
     */
    public static function expectsElixir(haxeCode: String, elixirCode: String) {
        // This is documentation only - actual validation happens in snapshot tests
        // But we trace it to help with debugging
        trace('Haxe: $haxeCode');
        trace('Expected Elixir: $elixirCode');
    }
}