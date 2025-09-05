package exunit;

/**
 * ExUnit assertion functions
 * 
 * Provides type-safe wrappers around ExUnit's assertion macros.
 * These compile to proper ExUnit assert calls in the generated Elixir.
 * 
 * ## Domain-Specific Assertions
 * 
 * This class includes specialized assertions for common functional types:
 * - `assertIsOk/assertIsError` for Result<T,E> types
 * - `assertIsSome/assertIsNone` for Option<T> types
 * 
 * ### WHY these are needed:
 * 
 * Result and Option types compile to tagged tuples in Elixir:
 * - Result.Ok(v) → {:ok, v}
 * - Result.Error(e) → {:error, e}
 * - Option.Some(v) → {:some, v}
 * - Option.None → :none
 * 
 * These assertions use Elixir's `match?/2` macro for pattern matching
 * rather than direct equality, making tests more idiomatic and readable.
 * 
 * Without these helpers, users would need to write:
 * ```haxe
 * // Awkward and error-prone
 * assertTrue(switch(result) { 
 *   case Ok(_): true; 
 *   case Error(_): false; 
 * });
 * ```
 * 
 * With these helpers:
 * ```haxe
 * // Clean and expressive
 * assertIsOk(result, "Operation should succeed");
 * ```
 */
class Assert {
    /**
     * Assert that two values are equal
     */
    extern inline public static function assertEqual<T>(expected: T, actual: T, ?message: String): Void {
        untyped __elixir__('assert {0} == {1}', actual, expected);
    }
    
    /**
     * Assert that two values are not equal
     */
    extern inline public static function assertNotEqual<T>(expected: T, actual: T, ?message: String): Void {
        untyped __elixir__('assert {0} != {1}', actual, expected);
    }
    
    /**
     * Assert that a condition is true
     */
    extern inline public static function assertTrue(condition: Bool, ?message: String): Void {
        untyped __elixir__('assert {0}', condition);
    }
    
    /**
     * Assert that a condition is false
     */
    extern inline public static function assertFalse(condition: Bool, ?message: String): Void {
        untyped __elixir__('assert not {0}', condition);
    }
    
    /**
     * Assert that a value is null/nil
     */
    extern inline public static function assertNull<T>(value: Null<T>, ?message: String): Void {
        untyped __elixir__('assert {0} == nil', value);
    }
    
    /**
     * Assert that a value is not null/nil
     */
    extern inline public static function assertNotNull<T>(value: Null<T>, ?message: String): Void {
        untyped __elixir__('assert {0} != nil', value);
    }
    
    /**
     * Assert that a function raises an exception
     */
    extern inline public static function assertRaises(fn: () -> Void, ?message: String): Void {
        untyped __elixir__('assert_raise RuntimeError, {0}', fn);
    }
    
    /**
     * Fail the test with a message
     */
    extern inline public static function fail(message: String): Void {
        untyped __elixir__('flunk({0})', message);
    }
    
    // Domain-specific assertions for functional types
    
    /**
     * Assert that a Result<T,E> is Ok.
     * 
     * WHY: Result types compile to {:ok, value} tuples in Elixir.
     * This assertion uses pattern matching for cleaner, more idiomatic tests.
     * 
     * @param result The Result to check
     * @param message Optional failure message
     */
    extern inline public static function assertIsOk<T,E>(result: Dynamic, ?message: String): Void {
        untyped __elixir__('assert match?({:ok, _}, {0})', result);
    }
    
    /**
     * Assert that a Result<T,E> is Error.
     * 
     * WHY: Result types compile to {:error, reason} tuples in Elixir.
     * This assertion uses pattern matching for cleaner, more idiomatic tests.
     * 
     * @param result The Result to check
     * @param message Optional failure message
     */
    extern inline public static function assertIsError<T,E>(result: Dynamic, ?message: String): Void {
        untyped __elixir__('assert match?({:error, _}, {0})', result);
    }
    
    /**
     * Assert that an Option<T> is Some.
     * 
     * WHY: Option types compile to {:some, value} tuples in Elixir.
     * This assertion uses pattern matching for cleaner, more idiomatic tests.
     * 
     * @param option The Option to check
     * @param message Optional failure message
     */
    extern inline public static function assertIsSome<T>(option: Dynamic, ?message: String): Void {
        untyped __elixir__('assert match?({:some, _}, {0})', option);
    }
    
    /**
     * Assert that an Option<T> is None.
     * 
     * WHY: Option.None compiles to the :none atom in Elixir.
     * This assertion provides type-safe checking for absent values.
     * 
     * @param option The Option to check
     * @param message Optional failure message
     */
    extern inline public static function assertIsNone<T>(option: Dynamic, ?message: String): Void {
        untyped __elixir__('assert {0} == :none', option);
    }
}