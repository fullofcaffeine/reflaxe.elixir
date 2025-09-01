/**
 * Std: Haxe Standard Library Core Functions
 * 
 * WHY: Haxe code expects certain standard functions to be available globally.
 * These functions provide essential type conversion and utility operations
 * that are used throughout all Haxe code.
 * 
 * WHAT: This class provides the core Std functions that will be optimized
 * by the Reflaxe compiler to native Elixir implementations.
 * 
 * HOW: Pure Haxe implementations or @:extern markers that the compiler
 * replaces with idiomatic Elixir patterns during transpilation.
 * 
 * @see https://api.haxe.org/Std.html - Official Haxe Std documentation
 */
class Std {
    /**
     * Convert any value to its string representation.
     * 
     * WHY: Universal string conversion is needed for debugging, logging, and display.
     * WHAT: Converts any Elixir value to its string representation.
     * HOW: The compiler will optimize this to proper Elixir string conversion.
     * 
     * @param value The value to convert to string (any type)
     * @return String representation of the value
     */
    extern public static function string<T>(value: T): String {
        // Compiler will replace with proper Elixir string conversion
        // case value do
        //   v when is_binary(v) -> v
        //   v when is_atom(v) -> Atom.to_string(v)
        //   v when is_integer(v) -> Integer.to_string(v)
        //   v when is_float(v) -> Float.to_string(v)
        //   nil -> "null"
        //   v -> inspect(v)
        // end
        return "";
    }
    
    /**
     * Parse a string to an integer.
     * 
     * WHY: String-to-integer conversion is common in input processing.
     * WHAT: Attempts to parse a string as an integer.
     * HOW: The compiler will optimize this to Integer.parse/1.
     * 
     * @param str The string to parse
     * @return The parsed integer or null if parsing fails
     */
    extern public static function parseInt(str: String): Null<Int> {
        // Compiler will replace with:
        // case Integer.parse(str) do
        //   {num, _} -> num
        //   :error -> nil
        // end
        return null;
    }
    
    /**
     * Parse a string to a float.
     * 
     * WHY: String-to-float conversion is needed for numeric input processing.
     * WHAT: Attempts to parse a string as a floating point number.
     * HOW: The compiler will optimize this to Float.parse/1.
     * 
     * @param str The string to parse
     * @return The parsed float or null if parsing fails
     */
    extern public static function parseFloat(str: String): Null<Float> {
        // Compiler will replace with:
        // case Float.parse(str) do
        //   {num, _} -> num
        //   :error -> nil
        // end
        return null;
    }
    
    /**
     * Check if a value is of a specific type (legacy API).
     * 
     * WHY: Runtime type checking is necessary for safe casts and validation.
     * WHAT: Checks if a value matches a given type at runtime.
     * HOW: The compiler will optimize this to Elixir type guards.
     * 
     * In Elixir, types are determined by:
     * - Basic types: checked with guards (is_integer, is_binary, etc.)
     * - Structs: checked via __struct__ field
     * - Enums: tagged tuples with first element as atom
     * 
     * @param value The value to check
     * @param type The type class to check against
     * @return True if the value is of the specified type
     */
    extern public static function is<T>(value: T, type: Class<T>): Bool {
        // Compiler will replace with proper type checking
        return false;
    }
    
    /**
     * Check if a value is of a specific type (newer API).
     * 
     * WHY: Type checking with more descriptive naming.
     * WHAT: Checks if a value is an instance of the specified type.
     * HOW: Delegates to is() with same implementation.
     * 
     * @param value The value to check
     * @param type The type class to check against
     * @return True if the value is of the specified type
     */
    public static inline function isOfType<T>(value: T, type: Class<T>): Bool {
        return is(value, type);
    }
    
    /**
     * Get a random float between 0 (inclusive) and 1 (exclusive).
     * 
     * WHY: Random number generation is needed for various algorithms.
     * WHAT: Generates a random float in the range [0, 1).
     * HOW: The compiler will optimize this to :rand.uniform/0.
     * 
     * @return Random float value between 0 and 1
     */
    extern public static function random(): Float {
        // Compiler will replace with :rand.uniform()
        return 0.0;
    }
    
    /**
     * Convert a float to an integer (truncates decimal part).
     * 
     * WHY: Float-to-integer conversion with truncation is a common operation.
     * WHAT: Truncates the decimal part of a float to get an integer.
     * HOW: The compiler will optimize this to trunc/1.
     * 
     * @param value The float to convert
     * @return Integer representation (truncated, not rounded)
     */
    extern public static function int(value: Float): Int {
        // Compiler will replace with trunc(value)
        return 0;
    }
}