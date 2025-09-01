/**
 * Reflect: Runtime Reflection API for Elixir Target
 * 
 * WHY: Haxe code often needs to access object fields dynamically at runtime,
 * especially when dealing with external data or dynamic structures. This is
 * essential for serialization, deserialization, and dynamic property access.
 * 
 * WHAT: Maps Haxe's reflection API to Elixir's Map operations. In Elixir,
 * objects are represented as maps, and field names are atoms. This class
 * provides the bridge between Haxe's string-based field access and Elixir's
 * atom-based map keys.
 * 
 * HOW: Pure Haxe implementation that the Reflaxe compiler optimizes to
 * native Elixir Map operations during transpilation.
 * 
 * ARCHITECTURE: Objects in generated Elixir code are maps where:
 * - Field names become atom keys
 * - Values retain their types
 * - Dynamic field access goes through Map module
 * 
 * @see https://api.haxe.org/Reflect.html - Official Haxe Reflect documentation
 */
class Reflect {
    /**
     * Get a field value from an object.
     * 
     * WHY: Dynamic field access is needed for deserialization and meta-programming.
     * WHAT: Retrieves a field value from an object (map) by field name.
     * HOW: The compiler will optimize this to Map.get with atom conversion.
     * 
     * EDGE CASES:
     * - Returns null if field doesn't exist
     * - Handles both atom and string field names in the map
     * - Works with nested maps/structs
     * 
     * @param obj The object (map) to get the field from
     * @param field The name of the field to retrieve
     * @return The value of the field, or null if it doesn't exist
     */
    extern public static function field<T, R>(obj: T, field: String): Null<R> {
        // Compiler will replace with Map.get(obj, String.to_existing_atom(field))
        return null;
    }
    
    /**
     * Set a field value on an object.
     * 
     * WHY: Dynamic field modification is needed for object construction and updates.
     * WHAT: Sets or updates a field value in an object (map).
     * HOW: The compiler will optimize this to Map.put.
     * 
     * NOTE: In Elixir, this returns a new map (immutability).
     * The original object is not modified.
     * 
     * @param obj The object (map) to set the field on
     * @param field The name of the field to set
     * @param value The value to set
     * @return The updated object (new map with the field set)
     */
    extern
    public static function setField<T, V>(obj: T, field: String, value: V): T {
        // Compiler will replace with Map.put(obj, String.to_atom(field), value)
        return obj;
    }
    
    /**
     * Get all field names from an object.
     * 
     * WHY: Needed for serialization, debugging, and meta-programming.
     * WHAT: Returns all field names (keys) from an object (map).
     * HOW: The compiler will optimize this to Map.keys.
     * 
     * @param obj The object (map) to get fields from
     * @return Array of field names as strings
     */
    extern
    public static function fields<T>(obj: T): Array<String> {
        // Compiler will replace with Map.keys(obj) |> Enum.map(&Atom.to_string/1)
        return [];
    }
    
    /**
     * Check if an object has a specific field.
     * 
     * WHY: Needed for optional field handling and defensive programming.
     * WHAT: Checks if an object (map) contains a specific field.
     * HOW: The compiler will optimize this to Map.has_key?.
     * 
     * @param obj The object (map) to check
     * @param field The name of the field to check for
     * @return True if the field exists, false otherwise
     */
    extern
    public static function hasField<T>(obj: T, field: String): Bool {
        // Compiler will replace with Map.has_key?(obj, String.to_existing_atom(field))
        return false;
    }
    
    /**
     * Delete a field from an object.
     * 
     * WHY: Needed for removing optional fields or cleaning objects.
     * WHAT: Removes a field from an object (map).
     * HOW: The compiler will optimize this to Map.delete.
     * 
     * NOTE: Returns a new map without the field (immutability).
     * 
     * @param obj The object (map) to delete the field from
     * @param field The name of the field to delete
     * @return The updated object (new map without the field)
     */
    extern
    public static function deleteField<T>(obj: T, field: String): T {
        // Compiler will replace with Map.delete(obj, String.to_existing_atom(field))
        return obj;
    }
    
    /**
     * Check if a value is an object (map in Elixir).
     * 
     * WHY: Type checking is needed for safe reflection operations.
     * WHAT: Determines if a value is an object that supports reflection.
     * HOW: The compiler will optimize this to is_map guard.
     * 
     * @param value The value to check
     * @return True if the value is an object/map
     */
    extern
    public static function isObject<T>(value: T): Bool {
        // Compiler will replace with is_map(value)
        return false;
    }
    
    /**
     * Make a shallow copy of an object with all its fields.
     * 
     * WHY: Object cloning is needed for immutable updates and snapshots.
     * WHAT: Creates a shallow copy of an object (map).
     * HOW: Maps are immutable in Elixir, so just returns the same map.
     * 
     * @param obj The object to copy
     * @return A shallow copy of the object
     */
    public static inline function copy<T>(obj: T): T {
        // In Elixir, maps are immutable, so we just return the same map
        // This maintains API compatibility while being efficient
        return obj;
    }
    
    /**
     * Call a method on an object dynamically.
     * 
     * WHY: Dynamic method invocation is needed for meta-programming and reflection.
     * WHAT: Calls a method/function with the given arguments.
     * HOW: The compiler will handle various Elixir callable types properly.
     * 
     * In Elixir, this handles:
     * - Function references: calls the function with obj as first argument
     * - Module functions: when passed as a function reference
     * 
     * @param obj The object to pass as context (can be null)
     * @param func The function to call
     * @param args Array of arguments to pass to the function
     * @return The return value of the function call
     */
    extern
    public static function callMethod<T, R>(obj: T, func: haxe.Constraints.Function, args: Array<{}>): R {
        // Compiler will replace with proper Elixir function application
        return null;
    }
    
    /**
     * Compare two values for ordering.
     * 
     * WHY: Needed for sorting and ordered data structures.
     * WHAT: Compares two values and returns their ordering.
     * HOW: Uses string comparison as a generic fallback.
     * 
     * @param a First value to compare
     * @param b Second value to compare
     * @return -1 if a < b, 0 if a == b, 1 if a > b
     */
    public static function compare<T>(a: T, b: T): Int {
        // Use string comparison as a generic fallback
        // The Reflaxe compiler will optimize this to native Elixir comparison
        var sa = Std.string(a);
        var sb = Std.string(b);
        if (sa < sb) return -1;
        if (sa > sb) return 1;
        return 0;
    }
    
    /**
     * Check if a value is an enum value.
     * 
     * WHY: Needed for enum type checking in runtime.
     * WHAT: Determines if a value is a Haxe enum value.
     * HOW: The compiler will check for tagged tuple structure.
     * 
     * In Elixir, Haxe enums are represented as:
     * - Simple constructors: atoms like :Constructor
     * - With parameters: tuples like {:Constructor, param1, param2}
     * 
     * @param value The value to check
     * @return True if the value is an enum value
     */
    extern
    public static function isEnumValue<T>(value: T): Bool {
        // Compiler will replace with proper enum detection
        return false;
    }
}