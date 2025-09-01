package elixir.types;

/**
 * Type-safe representation of Elixir's {:ok, value} | {:error, reason} pattern.
 * 
 * This enum provides compile-time safety for operations that can fail,
 * ensuring all error cases are handled explicitly.
 * 
 * ## Generic Type Parameters
 * - `T`: The type of the success value
 * - `E`: The type of the error (defaults to String for common error messages)
 * 
 * ## Usage Pattern
 * ```haxe
 * function divide(a: Float, b: Float): Result<Float, String> {
 *     if (b == 0) {
 *         return Error("Division by zero");
 *     }
 *     return Ok(a / b);
 * }
 * 
 * // Handle the result
 * switch(divide(10, 2)) {
 *     case Ok(value):
 *         trace("Result: " + value);
 *     case Error(reason):
 *         trace("Error: " + reason);
 * }
 * ```
 * 
 * ## Elixir Compilation
 * This compiles to idiomatic Elixir tuples:
 * - `Ok(value)` → `{:ok, value}`
 * - `Error(reason)` → `{:error, reason}`
 * 
 * ## Type Safety Benefits
 * - Forces explicit error handling at compile time
 * - Prevents null/undefined errors
 * - Provides clear API contracts
 * - Enables exhaustive pattern matching
 * 
 * @see Agent for usage with Agent operations
 * @see GenServer for usage with GenServer operations
 */
enum Result<T, E = String> {
    /**
     * Represents a successful operation with a value of type T.
     * Compiles to {:ok, value} in Elixir.
     */
    Ok(value: T);
    
    /**
     * Represents a failed operation with an error of type E.
     * Compiles to {:error, reason} in Elixir.
     */
    Error(reason: E);
}