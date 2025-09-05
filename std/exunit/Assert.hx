package exunit;

/**
 * ExUnit assertion functions
 * 
 * Provides type-safe wrappers around ExUnit's assertion macros.
 * These compile to proper ExUnit assert calls in the generated Elixir.
 */
class Assert {
    /**
     * Assert that two values are equal
     */
    public static function assertEqual<T>(expected: T, actual: T, ?message: String): Void {
        untyped __elixir__('assert {0} == {1}', actual, expected);
    }
    
    /**
     * Assert that two values are not equal
     */
    public static function assertNotEqual<T>(expected: T, actual: T, ?message: String): Void {
        untyped __elixir__('assert {0} != {1}', actual, expected);
    }
    
    /**
     * Assert that a condition is true
     */
    public static function assertTrue(condition: Bool, ?message: String): Void {
        untyped __elixir__('assert {0}', condition);
    }
    
    /**
     * Assert that a condition is false
     */
    public static function assertFalse(condition: Bool, ?message: String): Void {
        untyped __elixir__('assert not {0}', condition);
    }
    
    /**
     * Assert that a value is null/nil
     */
    public static function assertNull<T>(value: Null<T>, ?message: String): Void {
        untyped __elixir__('assert {0} == nil', value);
    }
    
    /**
     * Assert that a value is not null/nil
     */
    public static function assertNotNull<T>(value: Null<T>, ?message: String): Void {
        untyped __elixir__('assert {0} != nil', value);
    }
    
    /**
     * Assert that a function raises an exception
     */
    public static function assertRaises(fn: () -> Void, ?message: String): Void {
        untyped __elixir__('assert_raise RuntimeError, {0}', fn);
    }
}