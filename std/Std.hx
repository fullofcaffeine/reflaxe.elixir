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
    public static function string<T>(value: T): String {
        // Use native Elixir string conversion
        return untyped __elixir__('to_string({0})', value);
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
    public static function parseInt(str: String): Null<Int> {
        // Use native Elixir Integer.parse
        return untyped __elixir__('
            case Integer.parse({0}) do
                {num, _} -> num
                :error -> nil
            end
        ', str);
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
    public static function parseFloat(str: String): Null<Float> {
        // Use native Elixir Float.parse
        return untyped __elixir__('
            case Float.parse({0}) do
                {num, _} -> num
                :error -> nil
            end
        ', str);
    }
    
    /**
     * Check if a value is of a specific type at runtime.
     * 
     * ## WHY
     * Runtime type checking is necessary for safe casts, validation, and handling dynamic data
     * from external sources (JSON, user input, etc.) where compile-time type safety isn't available.
     * 
     * ## WHAT
     * Checks if a value matches a given type at runtime using Elixir's guard clauses and
     * pattern matching. Handles basic types, user-defined structs, and enum variants.
     * 
     * ## HOW IT WORKS
     * 
     * ### Basic Types
     * - `String` → `is_binary/1` (Elixir strings are binaries)
     * - `Int` → `is_integer/1`
     * - `Float` → `is_float/1`
     * - `Bool` → `is_boolean/1`
     * - `Array` → `is_list/1` (Haxe arrays compile to Elixir lists)
     * - `Map` → `is_map/1`
     * 
     * ### User-Defined Types
     * - **Structs**: Checks the `__struct__` field for type matching
     * - **Enums**: Checks tagged tuples where first element is the constructor atom
     * - **Classes**: Compares against the module atom for struct types
     * 
     * ## LIMITATIONS & PITFALLS
     * 
     * ### 1. Type Erasure
     * Generic type parameters are erased at runtime:
     * ```haxe
     * Std.is([1, 2, 3], Array<Int>);    // ❌ Can't check element types
     * Std.is([1, 2, 3], Array);         // ✅ Can only check it's an array
     * ```
     * 
     * ### 2. Interface Checking
     * Interfaces don't exist at runtime in Elixir, so interface checks won't work:
     * ```haxe
     * interface ISerializable { }
     * Std.is(obj, ISerializable);       // ❌ Will always return false
     * ```
     * 
     * ### 3. Abstract Types
     * Abstract types are compile-time only and don't exist at runtime:
     * ```haxe
     * abstract UserId(Int) {}
     * Std.is(42, UserId);               // ❌ Will check for Int, not UserId
     * ```
     * 
     * ### 4. Null Handling
     * `null` (nil in Elixir) will return false for all type checks except:
     * ```haxe
     * Std.is(null, Null<T>);            // Implementation-dependent
     * ```
     * 
     * ### 5. Dynamic Type
     * Everything matches Dynamic since it represents "any type":
     * ```haxe
     * Std.is(anything, Dynamic);        // Always true (not implemented here)
     * ```
     * 
     * ### 6. Enum Limitations
     * Only checks constructor, not parameter types:
     * ```haxe
     * enum Option<T> { Some(v: T); None; }
     * Std.is(Some("hello"), Option);    // ✅ Works
     * Std.is(Some("hello"), Some);      // ⚠️ Checks for :Some atom
     * ```
     * 
     * ### 7. Anonymous Structures
     * Anonymous structures compile to maps, so specific field checking isn't done:
     * ```haxe
     * typedef Point = { x: Int, y: Int }
     * Std.is({x: 1, y: 2}, Point);      // ❌ Just checks if it's a map
     * ```
     * 
     * ## EDGE CASES
     * - Empty arrays/maps will match their respective types
     * - Atoms are not directly checkable from Haxe types
     * - Tuples without atom tags won't match enum patterns
     * - Recursive type checking is not performed on container contents
     * 
     * ## RECOMMENDED USAGE
     * Best used for:
     * - Checking basic types from dynamic sources
     * - Validating struct types before casting
     * - Simple enum constructor checking
     * 
     * Avoid for:
     * - Generic type parameter validation
     * - Interface implementation checking
     * - Complex nested type validation
     * 
     * @param value The value to check (can be null)
     * @param type The type class to check against
     * @return True if the value is of the specified type, false otherwise
     */
    public static function is(value: Dynamic, type: Dynamic): Bool {
        // Runtime type checking for Elixir types
        // Handles basic types, structs, and enums (as tagged tuples)
        return untyped __elixir__('
            # Convert type to string for comparison
            type_str = to_string({1})
            
            case type_str do
                "String" -> is_binary({0})
                "Float" -> is_float({0})
                "Int" -> is_integer({0})
                "Bool" -> is_boolean({0})
                "Array" -> is_list({0})
                "Map" -> is_map({0})
                _ ->
                    # For user-defined types, check if it\'s a struct with matching __struct__ field
                    case {0} do
                        %{__struct__: struct_type} -> struct_type == {1}
                        # For enums (tagged tuples), check if first element matches the type atom
                        {tag, _} when is_atom(tag) -> tag == {1}
                        {tag, _, _} when is_atom(tag) -> tag == {1}
                        {tag, _, _, _} when is_atom(tag) -> tag == {1}
                        _ -> false
                    end
            end
        ', value, type);
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
    public static inline function isOfType(value: Dynamic, type: Dynamic): Bool {
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
    public static function random(): Float {
        // Use Erlang's :rand.uniform() for random number generation
        return untyped __elixir__(':rand.uniform()');
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
    public static function int(value: Float): Int {
        // Use Elixir's trunc to convert float to integer (truncates decimal part)
        return untyped __elixir__('trunc({0})', value);
    }
}