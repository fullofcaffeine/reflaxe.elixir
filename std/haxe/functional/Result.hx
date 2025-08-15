package haxe.functional;

/**
 * Universal Result<T,E> algebraic data type for safe error handling.
 * 
 * Compiles to idiomatic constructs per target:
 * - Elixir: {:ok, value} / {:error, reason} tuples
 * - JavaScript: discriminated unions with tagged types
 * - Python: dataclasses with proper type hints
 * - Other targets: standard enum with type safety
 * 
 * This implementation prioritizes:
 * - Type safety across all targets
 * - Functional composition patterns
 * - Exhaustive pattern matching support
 * - Zero-cost abstractions where possible
 * 
 * @see ResultTools for functional operations (map, flatMap, fold, etc.)
 */
enum Result<T, E> {
    /**
     * Successful result containing a value of type T
     * @param value The successful result value
     */
    Ok(value: T);
    
    /**
     * Error result containing an error of type E
     * @param error The error information
     */
    Error(error: E);
}

/**
 * Companion class providing functional operations for Result<T,E>
 * 
 * Implements the full functional toolkit for Result types:
 * - Functor operations (map)
 * - Monad operations (flatMap/bind)
 * - Foldable operations (fold)
 * - Utility functions (isOk, isError, unwrap)
 * 
 * All operations are designed to work seamlessly across all Haxe targets
 * while generating optimal target-specific code.
 */
class ResultTools {
    
    /**
     * Apply a function to the success value, leaving errors unchanged.
     * 
     * This is the Functor map operation for Result types.
     * 
     * @param result The result to transform
     * @param transform Function to apply to success values
     * @return New result with transformed success value or unchanged error
     */
    public static function map<T, U, E>(result: Result<T, E>, transform: T -> U): Result<U, E> {
        return switch (result) {
            case Ok(value): Ok(transform(value));
            case Error(error): Error(error);
        }
    }
    
    /**
     * Apply a function that returns a Result, flattening nested Results.
     * 
     * This is the Monad bind/flatMap operation for Result types.
     * Essential for chaining operations that can fail.
     * 
     * @param result The result to transform
     * @param transform Function that takes success value and returns a Result
     * @return Flattened result of the transformation
     */
    public static function flatMap<T, U, E>(result: Result<T, E>, transform: T -> Result<U, E>): Result<U, E> {
        return switch (result) {
            case Ok(value): transform(value);
            case Error(error): Error(error);
        }
    }
    
    /**
     * Alternative name for flatMap following Haskell/Rust conventions.
     * @see flatMap
     */
    public static inline function bind<T, U, E>(result: Result<T, E>, transform: T -> Result<U, E>): Result<U, E> {
        return flatMap(result, transform);
    }
    
    /**
     * Extract a value from Result by providing handlers for both cases.
     * 
     * This is the canonical way to consume a Result value.
     * Ensures exhaustive handling of both success and error cases.
     * 
     * @param result The result to fold
     * @param onSuccess Function to handle success values
     * @param onError Function to handle error values
     * @return The result of applying the appropriate handler
     */
    public static function fold<T, E, R>(result: Result<T, E>, onSuccess: T -> R, onError: E -> R): R {
        return switch (result) {
            case Ok(value): onSuccess(value);
            case Error(error): onError(error);
        }
    }
    
    /**
     * Check if result represents a successful value.
     * @param result The result to check
     * @return true if result is Ok, false if Error
     */
    public static function isOk<T, E>(result: Result<T, E>): Bool {
        return switch (result) {
            case Ok(_): true;
            case Error(_): false;
        }
    }
    
    /**
     * Check if result represents an error.
     * @param result The result to check
     * @return true if result is Error, false if Ok
     */
    public static function isError<T, E>(result: Result<T, E>): Bool {
        return switch (result) {
            case Ok(_): false;
            case Error(_): true;
        }
    }
    
    /**
     * Extract the success value, throwing an exception if it's an error.
     * 
     * Use with caution - prefer pattern matching or fold for safe extraction.
     * 
     * @param result The result to unwrap
     * @return The success value
     * @throws String if result is an Error
     */
    public static function unwrap<T, E>(result: Result<T, E>): T {
        return switch (result) {
            case Ok(value): value;
            case Error(error): throw 'Attempted to unwrap Error result: ${error}';
        }
    }
    
    /**
     * Extract the success value or return a default.
     * 
     * Safe alternative to unwrap that never throws.
     * 
     * @param result The result to unwrap
     * @param defaultValue Value to return if result is Error
     * @return Success value or default
     */
    public static function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
        return switch (result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        }
    }
    
    /**
     * Extract the success value or compute a default from the error.
     * 
     * @param result The result to unwrap
     * @param errorHandler Function to compute default from error
     * @return Success value or computed default
     */
    public static function unwrapOrElse<T, E>(result: Result<T, E>, errorHandler: E -> T): T {
        return switch (result) {
            case Ok(value): value;
            case Error(error): errorHandler(error);
        }
    }
    
    /**
     * Transform the error type, leaving success values unchanged.
     * 
     * @param result The result to transform
     * @param transform Function to apply to error values
     * @return Result with transformed error type
     */
    public static function mapError<T, E, F>(result: Result<T, E>, transform: E -> F): Result<T, F> {
        return switch (result) {
            case Ok(value): Ok(value);
            case Error(error): Error(transform(error));
        }
    }
    
    /**
     * Apply a Result-returning function to both success and error cases.
     * 
     * This allows converting between different Result types entirely.
     * 
     * @param result The result to transform
     * @param onSuccess Function to transform success values
     * @param onError Function to transform error values
     * @return New result from appropriate transformation
     */
    public static function bimap<T, U, E, F>(result: Result<T, E>, onSuccess: T -> U, onError: E -> F): Result<U, F> {
        return switch (result) {
            case Ok(value): Ok(onSuccess(value));
            case Error(error): Error(onError(error));
        }
    }
    
    /**
     * Create a successful Result.
     * 
     * Convenience constructor function.
     * 
     * @param value The success value
     * @return Ok Result containing the value
     */
    public static inline function ok<T, E>(value: T): Result<T, E> {
        return Ok(value);
    }
    
    /**
     * Create an error Result.
     * 
     * Convenience constructor function.
     * 
     * @param error The error value
     * @return Error Result containing the error
     */
    public static inline function error<T, E>(error: E): Result<T, E> {
        return Error(error);
    }
    
    /**
     * Convert an Array of Results into a Result of Array.
     * 
     * Returns Ok with all values if all Results are Ok,
     * or the first Error encountered.
     * 
     * @param results Array of Results to sequence
     * @return Result containing array of all values or first error
     */
    public static function sequence<T, E>(results: Array<Result<T, E>>): Result<Array<T>, E> {
        var values: Array<T> = [];
        
        for (result in results) {
            switch (result) {
                case Ok(value): 
                    values.push(value);
                case Error(error): 
                    return Error(error);
            }
        }
        
        return Ok(values);
    }
    
    /**
     * Apply a function to an array, collecting successful Results.
     * 
     * Like Array.map but collects all Results into a single Result.
     * Fails fast on the first error encountered.
     * 
     * @param array Array of input values
     * @param transform Function that may fail
     * @return Result containing array of all successes or first error
     */
    public static function traverse<T, U, E>(array: Array<T>, transform: T -> Result<U, E>): Result<Array<U>, E> {
        var results = array.map(transform);
        return sequence(results);
    }
}