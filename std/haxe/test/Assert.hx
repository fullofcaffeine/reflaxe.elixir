package haxe.test;

import elixir.types.Term;

/**
 * ExUnit assertion API for Haxe tests.
 * 
 * Provides type-safe assertions that compile to ExUnit assertion macros.
 * All assertions generate helpful error messages with actual vs expected values.
 * 
 * ## Basic Usage
 * 
 * ```haxe
 * Assert.isTrue(someCondition);
 * Assert.equals(expected, actual);
 * Assert.isNotNull(maybeNullValue);
 * ```
 * 
 * ## Option/Result Integration
 * 
 * ```haxe
 * var user: Option<User> = findUser(1);
 * Assert.isSome(user);
 * Assert.isNone(findUser(-1));
 * 
 * var result: Result<String, String> = parseInput("123");
 * Assert.isOk(result);
 * Assert.isError(parseInput("invalid"));
 * ```
 */
class Assert {
    /**
     * Assert that a value is true.
     * 
     * @param value Value to check
     * @param message Optional failure message
     */
    public static function isTrue(value: Bool, ?message: String): Void {
        // Implementation handled by ExUnitCompiler
        throw "Assert.isTrue should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a value is false.
     * 
     * @param value Value to check
     * @param message Optional failure message
     */
    public static function isFalse(value: Bool, ?message: String): Void {
        throw "Assert.isFalse should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that two values are equal.
     * Uses Elixir's == operator for comparison.
     * 
     * @param expected Expected value
     * @param actual Actual value
     * @param message Optional failure message
     */
    public static function equals<T>(expected: T, actual: T, ?message: String): Void {
        throw "Assert.equals should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that two values are not equal.
     * 
     * @param expected Value that should not match
     * @param actual Actual value
     * @param message Optional failure message
     */
    public static function notEquals<T>(expected: T, actual: T, ?message: String): Void {
        throw "Assert.notEquals should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a value is null.
     * 
     * @param value Value to check
     * @param message Optional failure message
     */
    public static function isNull<T>(value: T, ?message: String): Void {
        throw "Assert.isNull should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a value is not null.
     * 
     * @param value Value to check
     * @param message Optional failure message
     */
    public static function isNotNull<T>(value: T, ?message: String): Void {
        throw "Assert.isNotNull should be compiled by ExUnitCompiler";
    }

    /**
     * Backwards-compatible alias for isNotNull
     */
    public static inline function notNull<T>(value: T, ?message: String): Void {
        isNotNull(value, message);
    }
    
    /**
     * Assert that an Option contains a value (is Some).
     * 
     * @param option Option to check
     * @param message Optional failure message
     */
    public static function isSome<T>(option: haxe.ds.Option<T>, ?message: String): Void {
        throw "Assert.isSome should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that an Option is empty (is None).
     * 
     * @param option Option to check
     * @param message Optional failure message
     */
    public static function isNone<T>(option: haxe.ds.Option<T>, ?message: String): Void {
        throw "Assert.isNone should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a Result is successful (is Ok).
     * 
     * @param result Result to check
     * @param message Optional failure message
     */
    public static function isOk<T, E>(result: haxe.functional.Result<T, E>, ?message: String): Void {
        throw "Assert.isOk should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a Result is an error (is Error).
     * 
     * @param result Result to check
     * @param message Optional failure message
     */
    public static function isError<T, E>(result: haxe.functional.Result<T, E>, ?message: String): Void {
        throw "Assert.isError should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a function raises an exception.
     * 
     * @param fn Function to execute
     * @param exceptionModule Expected exception module (optional, Elixir module atom)
     * @param message Optional failure message
     */
    public static function raises(fn: () -> Void, ?exceptionModule: Term, ?message: String): Void {
        throw "Assert.raises should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a function does not raise an exception.
     * 
     * @param fn Function to execute
     * @param message Optional failure message
     */
    public static function doesNotRaise(fn: () -> Void, ?message: String): Void {
        throw "Assert.doesNotRaise should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a collection contains an item.
     * 
     * @param collection Collection to search
     * @param item Item to find
     * @param message Optional failure message
     */
    public static function contains<T>(collection: Array<T>, item: T, ?message: String): Void {
        throw "Assert.contains should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a string contains a substring.
     * 
     * @param haystack String to search in
     * @param needle Substring to find
     * @param message Optional failure message
     */
    public static function containsString(haystack: String, needle: String, ?message: String): Void {
        throw "Assert.containsString should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a string does not contain a substring.
     * 
     * @param haystack String to search in
     * @param needle Substring that should not be found
     * @param message Optional failure message
     */
    public static function doesNotContainString(haystack: String, needle: String, ?message: String): Void {
        throw "Assert.doesNotContainString should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a collection is empty.
     * 
     * @param collection Collection to check
     * @param message Optional failure message
     */
    public static function isEmpty<T>(collection: Array<T>, ?message: String): Void {
        throw "Assert.isEmpty should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a collection is not empty.
     * 
     * @param collection Collection to check
     * @param message Optional failure message
     */
    public static function isNotEmpty<T>(collection: Array<T>, ?message: String): Void {
        throw "Assert.isNotEmpty should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that two floating point numbers are equal within a delta.
     * 
     * @param expected Expected value
     * @param actual Actual value
     * @param delta Maximum allowed difference
     * @param message Optional failure message
     */
    public static function inDelta(expected: Float, actual: Float, delta: Float, ?message: String): Void {
        throw "Assert.inDelta should be compiled by ExUnitCompiler";
    }
    
    /**
     * Force a test failure with a message.
     * 
     * @param message Failure message
     */
    public static function fail(message: String): Void {
        throw "Assert.fail should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a pattern matches a value.
     * Uses Elixir pattern matching for validation.
     * 
     * @param pattern Pattern to match against
     * @param value Value to check
     * @param message Optional failure message
     */
    public static function matches<T>(pattern: T, value: T, ?message: String): Void {
        throw "Assert.matches should be compiled by ExUnitCompiler";
    }
    
    /**
     * Assert that a message matching the pattern was received.
     * For testing OTP processes and message passing.
     * 
     * @param pattern Message pattern to match
     * @param timeout Timeout in milliseconds (default: 100)
     * @param message Optional failure message
     */
    public static function received(pattern: Term, ?timeout: Int = 100, ?message: String): Void {
        throw "Assert.received should be compiled by ExUnitCompiler";
    }
}
