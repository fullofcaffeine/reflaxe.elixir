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
@:elixirIdiomatic
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

