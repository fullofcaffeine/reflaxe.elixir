package haxe.ds;

import haxe.functional.Result;

/**
 * Functional operations for Option<T> types with BEAM-first design.
 * 
 * Inspired by Gleam's approach: complete type safety, functional composition,
 * and seamless integration with OTP/BEAM patterns.
 * 
 * ## Design Philosophy
 * 
 * All operations follow Gleam's naming conventions and functional programming
 * principles while compiling to idiomatic BEAM code:
 * 
 * - **Functor operations**: map for transforming contained values
 * - **Monad operations**: then (flatMap) for chaining Option-returning functions  
 * - **Collection operations**: all, values for working with arrays
 * - **BEAM integration**: toResult, toReply for OTP patterns
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Gleam-style chaining
 * var result = findUser(id)
 *     .map(user -> user.email)
 *     .filter(email -> email.contains("@"))
 *     .unwrap("unknown@example.com");
 * 
 * // OTP GenServer integration
 * var reply = getUser(id).toReply();  // {:reply, {:some, user}, state}
 * 
 * // Error handling chains
 * var outcome = findUser(id)
 *     .toResult("User not found")
 *     .then(user -> updateUser(user, data));
 * ```
 */
class OptionTools {
    
    /**
     * Transform the value inside Some, leaving None unchanged.
     * 
     * This is the Functor map operation. In Gleam terms, it applies a function
     * to the wrapped value if present, otherwise returns None.
     * 
     * @param option The option to transform
     * @param transform Function to apply to the contained value
     * @return New option with transformed value or None
     */
    public static function map<T, U>(option: Option<T>, transform: T -> U): Option<U> {
        return switch (option) {
            case Some(value): Some(transform(value));
            case None: None;
        }
    }
    
    /**
     * Apply a function that returns an Option, flattening nested Options.
     * 
     * This is the Monad bind operation. Gleam calls this 'then'.
     * Essential for chaining operations that may return None.
     * 
     * @param option The option to transform
     * @param transform Function that takes value and returns an Option
     * @return Flattened result of the transformation
     */
    public static function then<T, U>(option: Option<T>, transform: T -> Option<U>): Option<U> {
        return switch (option) {
            case Some(value): transform(value);
            case None: None;
        }
    }
    
    /**
     * Alternative name for 'then' following Haskell/Rust conventions.
     * @see then
     */
    public static inline function flatMap<T, U>(option: Option<T>, transform: T -> Option<U>): Option<U> {
        return then(option, transform);
    }
    
    /**
     * Flatten nested Options into a single Option.
     * 
     * Converts Option<Option<T>> to Option<T>.
     * Following Gleam's flatten operation.
     * 
     * @param option The nested option to flatten
     * @return Flattened option
     */
    public static function flatten<T>(option: Option<Option<T>>): Option<T> {
        return switch (option) {
            case Some(inner): inner;
            case None: None;
        }
    }
    
    /**
     * Keep the Option only if the contained value satisfies a predicate.
     * 
     * @param option The option to filter
     * @param predicate Function to test the contained value
     * @return Original option if predicate passes, None otherwise
     */
    public static function filter<T>(option: Option<T>, predicate: T -> Bool): Option<T> {
        return switch (option) {
            case Some(value): predicate(value) ? Some(value) : None;
            case None: None;
        }
    }
    
    /**
     * Extract the contained value or return a default.
     * 
     * Following Gleam's 'unwrap' naming convention.
     * Safe extraction that never crashes.
     * 
     * @param option The option to unwrap
     * @param defaultValue Value to return if option is None
     * @return Contained value or default
     */
    public static function unwrap<T>(option: Option<T>, defaultValue: T): T {
        return switch (option) {
            case Some(value): value;
            case None: defaultValue;
        }
    }
    
    /**
     * Extract the contained value or compute a default lazily.
     * 
     * Following Gleam's 'lazy_unwrap' pattern for expensive defaults.
     * 
     * @param option The option to unwrap
     * @param fn Function to compute default if needed
     * @return Contained value or computed default
     */
    public static function lazyUnwrap<T>(option: Option<T>, fn: () -> T): T {
        return switch (option) {
            case Some(value): value;
            case None: fn();
        }
    }
    
    /**
     * Return the first option if it contains a value, otherwise the second.
     * 
     * Following Gleam's 'or' operation for combining Options.
     * 
     * @param first First option to try
     * @param second Fallback option
     * @return First option if Some, otherwise second option
     */
    public static function or<T>(first: Option<T>, second: Option<T>): Option<T> {
        return switch (first) {
            case Some(_): first;
            case None: second;
        }
    }
    
    /**
     * Return the first option if it contains a value, otherwise compute fallback.
     * 
     * Following Gleam's 'lazy_or' pattern for expensive alternatives.
     * 
     * @param first First option to try
     * @param fn Function to compute alternative option
     * @return First option if Some, otherwise computed alternative
     */
    public static function lazyOr<T>(first: Option<T>, fn: () -> Option<T>): Option<T> {
        return switch (first) {
            case Some(_): first;
            case None: fn();
        }
    }
    
    /**
     * Check if the option contains a value.
     * 
     * @param option The option to check
     * @return true if Some, false if None
     */
    public static function isSome<T>(option: Option<T>): Bool {
        return switch (option) {
            case Some(_): true;
            case None: false;
        }
    }
    
    /**
     * Check if the option is empty.
     * 
     * @param option The option to check
     * @return true if None, false if Some
     */
    public static function isNone<T>(option: Option<T>): Bool {
        return switch (option) {
            case Some(_): false;
            case None: true;
        }
    }
    
    /**
     * Convert all Options in an array to an array of values.
     * 
     * Following Gleam's 'all' operation. Returns Some(array) if all options
     * contain values, otherwise None.
     * 
     * @param options Array of options to combine
     * @return Some containing array of all values, or None if any option is None
     */
    public static function all<T>(options: Array<Option<T>>): Option<Array<T>> {
        var values: Array<T> = [];
        
        for (option in options) {
            switch (option) {
                case Some(value): 
                    values.push(value);
                case None: 
                    return None;
            }
        }
        
        return Some(values);
    }
    
    /**
     * Extract all Some values from an array of Options, discarding None values.
     * 
     * Following Gleam's 'values' operation. Always succeeds, returning
     * an array containing only the unwrapped Some values.
     * 
     * @param options Array of options to extract values from
     * @return Array containing all unwrapped Some values
     */
    public static function values<T>(options: Array<Option<T>>): Array<T> {
        var result: Array<T> = [];
        
        for (option in options) {
            switch (option) {
                case Some(value): 
                    result.push(value);
                case None: 
                    // Skip None values
            }
        }
        
        return result;
    }
    
    // === BEAM/OTP Integration ===
    
    /**
     * Convert Option to Result for error handling chains.
     * 
     * Essential for OTP patterns where absence is an error condition.
     * Enables chaining with other Result-returning functions.
     * 
     * @param option The option to convert
     * @param error Error value to use if option is None
     * @return Ok with contained value, or Error with provided error
     */
    public static function toResult<T, E>(option: Option<T>, error: E): Result<T, E> {
        return switch (option) {
            case Some(value): Ok(value);
            case None: Error(error);
        }
    }
    
    /**
     * Convert Result to Option, discarding error information.
     * 
     * Useful when you only care about success/failure, not the specific error.
     * 
     * @param result The result to convert
     * @return Some with success value, or None for any error
     */
    public static function fromResult<T, E>(result: Result<T, E>): Option<T> {
        return switch (result) {
            case Ok(value): Some(value);
            case Error(_): None;
        }
    }
    
    /**
     * Convert nullable value to Option.
     * 
     * Bridge between Haxe's nullable types and type-safe Option handling.
     * 
     * @param value Nullable value to convert
     * @return Some(value) if not null, None if null
     */
    public static function fromNullable<T>(value: Null<T>): Option<T> {
        return value != null ? Some(value) : None;
    }
    
    /**
     * Convert Option to nullable value.
     * 
     * For interop with APIs that expect nullable types.
     * Use sparingly - prefer Option for type safety.
     * 
     * @param option The option to convert
     * @return Contained value or null
     */
    public static function toNullable<T>(option: Option<T>): Null<T> {
        return switch (option) {
            case Some(value): value;
            case None: null;
        }
    }
    
    /**
     * Convert Option to OTP-style reply tuple.
     * 
     * For GenServer handle_call implementations. Generates appropriate
     * {:reply, response, state} patterns.
     * 
     * @param option The option to convert to reply
     * @return Dynamic tuple appropriate for GenServer replies
     */
    public static function toReply<T>(option: Option<T>): Dynamic {
        return switch (option) {
            case Some(value): {reply: value, status: "ok"};
            case None: {reply: null, status: "none"};
        }
    }
    
    /**
     * Extract value with clear crash message if None.
     * 
     * Following Gleam's philosophy: crash fast with helpful error messages.
     * Use only when None indicates a programming error.
     * 
     * @param option The option to extract from
     * @param message Error message for the crash
     * @return The contained value (never returns if None)
     * @throws String if option is None
     */
    public static function expect<T>(option: Option<T>, message: String): T {
        return switch (option) {
            case Some(value): value;
            case None: throw 'Expected Some value but got None: ${message}';
        }
    }
    
    /**
     * Convenience constructor for Some values.
     * 
     * @param value The value to wrap
     * @return Some containing the value
     */
    public static inline function some<T>(value: T): Option<T> {
        return Some(value);
    }
    
    /**
     * Convenience constructor for None values.
     * 
     * @return None option
     */
    public static inline function none<T>(): Option<T> {
        return None;
    }
    
    /**
     * Apply a side-effect function to the contained value if present.
     * 
     * Useful for performing actions on Some values without changing the Option.
     * 
     * @param option The option to apply the function to
     * @param fn Function to apply for side effects
     * @return The original option unchanged
     */
    public static function apply<T>(option: Option<T>, fn: T -> Void): Option<T> {
        switch (option) {
            case Some(value): fn(value);
            case None: // Do nothing
        }
        return option;
    }
}