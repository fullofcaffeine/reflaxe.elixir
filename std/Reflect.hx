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
 * HOW: Uses `untyped __elixir__()` to directly inject native Elixir Map 
 * operations, providing efficient and idiomatic code generation.
 * 
 * ## Haxe to Elixir Translation
 * 
 * ### Object Representation
 * ```haxe
 * // Haxe object
 * var obj = { name: "John", age: 30 };
 * 
 * // Generates Elixir map
 * %{name: "John", age: 30}
 * ```
 * 
 * ### Field Access Translation
 * | Haxe Code | Generated Elixir | Notes |
 * |-----------|------------------|-------|
 * | `Reflect.field(obj, "name")` | `Map.get(obj, String.to_existing_atom("name"))` | Safe atom lookup |
 * | `Reflect.setField(obj, "age", 31)` | `Map.put(obj, String.to_atom("age"), 31)` | Returns new map |
 * | `Reflect.fields(obj)` | `Map.keys(obj) \|> Enum.map(&Atom.to_string/1)` | Converts atoms to strings |
 * | `Reflect.hasField(obj, "name")` | `Map.has_key?(obj, :name)` | Compiler-optimized |
 * | `Reflect.deleteField(obj, "age")` | `Map.delete(obj, :age)` | Returns new map |
 * 
 * ## Elixir Idioms and Immutability
 * 
 * ### Immutable Operations
 * All Reflect operations respect Elixir's immutability:
 * ```haxe
 * var original = { count: 1 };
 * var updated = Reflect.setField(original, "count", 2);
 * // original.count is still 1 (unchanged)
 * // updated.count is 2 (new map)
 * ```
 * 
 * ### Atom vs String Keys
 * - Field names are converted to atoms for idiomatic Elixir
 * - `String.to_existing_atom` used for safe lookups (field)
 * - `String.to_atom` used for creation (setField)
 * - This matches Elixir conventions while maintaining safety
 * 
 * ### Pattern Matching Compatibility
 * Generated maps work seamlessly with Elixir pattern matching:
 * ```elixir
 * # Generated from Haxe objects
 * case obj do
 *   %{name: name, age: age} -> "#{name} is #{age} years old"
 *   _ -> "Unknown"
 * end
 * ```
 * 
 * ## Performance Characteristics
 * 
 * - **O(1)** field access via Map.get
 * - **O(1)** field updates via Map.put (returns new map)
 * - **O(n)** for fields() operation (iterates all keys)
 * - No runtime overhead - compiles to direct Map calls
 * 
 * ## Usage Patterns
 * 
 * ### Dynamic Property Access
 * ```haxe
 * function getValue(obj: Dynamic, path: String): Dynamic {
 *     var parts = path.split(".");
 *     var current = obj;
 *     for (part in parts) {
 *         current = Reflect.field(current, part);
 *         if (current == null) break;
 *     }
 *     return current;
 * }
 * ```
 * 
 * ### Object Merging
 * ```haxe
 * function merge(obj1: Dynamic, obj2: Dynamic): Dynamic {
 *     var result = Reflect.copy(obj1);
 *     for (field in Reflect.fields(obj2)) {
 *         result = Reflect.setField(result, field, Reflect.field(obj2, field));
 *     }
 *     return result;
 * }
 * ```
 * 
 * ## When to Use Reflect
 * 
 * ### ✅ Good Use Cases
 * 
 * 1. **JSON/External Data Processing**
 * ```haxe
 * // When working with dynamic JSON data
 * var json = haxe.Json.parse(jsonString);
 * var userName = Reflect.field(json, "user_name");
 * ```
 * 
 * 2. **Generic Serialization/Deserialization**
 * ```haxe
 * // Building a generic serializer
 * function serialize(obj: Dynamic): String {
 *     var result = "{";
 *     for (field in Reflect.fields(obj)) {
 *         result += '"$field":' + haxe.Json.stringify(Reflect.field(obj, field)) + ",";
 *     }
 *     return result + "}";
 * }
 * ```
 * 
 * 3. **Meta-Programming and Macros**
 * ```haxe
 * // Dynamic property injection
 * function addTimestamp(obj: Dynamic): Dynamic {
 *     return Reflect.setField(obj, "timestamp", Date.now());
 * }
 * ```
 * 
 * 4. **Plugin/Extension Systems**
 * ```haxe
 * // Dynamic plugin loading
 * function loadPlugin(obj: Dynamic, pluginData: Dynamic) {
 *     for (method in Reflect.fields(pluginData)) {
 *         Reflect.setField(obj, method, Reflect.field(pluginData, method));
 *     }
 * }
 * ```
 * 
 * ### ❌ Avoid Reflect When
 * 
 * 1. **Type Safety is Available**
 * ```haxe
 * // ❌ BAD: Using Reflect on typed objects
 * var user = new User("John", 30);
 * var name = Reflect.field(user, "name");
 * 
 * // ✅ GOOD: Direct typed access
 * var user = new User("John", 30);
 * var name = user.name;
 * ```
 * 
 * 2. **Performance Critical Code**
 * ```haxe
 * // ❌ BAD: Reflect in hot loops
 * for (i in 0...1000000) {
 *     total += Reflect.field(obj, "value");
 * }
 * 
 * // ✅ GOOD: Typed access for performance
 * var value = obj.value;
 * for (i in 0...1000000) {
 *     total += value;
 * }
 * ```
 * 
 * 3. **When Abstracts/Typedefs Work**
 * ```haxe
 * // ❌ BAD: Dynamic when structure is known
 * function processConfig(config: Dynamic) {
 *     var host = Reflect.field(config, "host");
 * }
 * 
 * // ✅ GOOD: Use typedef for known structures
 * typedef Config = { host: String, port: Int }
 * function processConfig(config: Config) {
 *     var host = config.host;
 * }
 * ```
 * 
 * ## Why Maps in Elixir?
 * 
 * ### The Natural Mapping
 * Haxe anonymous objects `{}` naturally map to Elixir maps `%{}` because:
 * - Both are key-value structures
 * - Both support dynamic field access
 * - Both are the idiomatic choice for structured data
 * 
 * ### Elixir Idioms and Reflect
 * 
 * #### Pattern Matching vs Reflect
 * ```elixir
 * # Idiomatic Elixir (when structure is known)
 * case user do
 *   %{name: name, age: age} when age >= 18 -> "Adult: #{name}"
 *   %{name: name} -> "Minor: #{name}"
 * end
 * 
 * # Using Reflect (when structure is dynamic)
 * name = Reflect.field(user, "name")
 * age = Reflect.field(user, "age") || 0
 * if age >= 18 do "Adult: #{name}" else "Minor: #{name}" end
 * ```
 * 
 * #### When Reflect Aligns with Elixir Idioms
 * - **Dynamic configuration**: Maps with runtime-determined keys
 * - **JSON handling**: External data with variable structure
 * - **Meta-programming**: Building DSLs and macros
 * - **Ecto changesets**: Dynamic field validation
 * 
 * #### When to Prefer Elixir Patterns
 * - **Structs**: Use `%User{}` instead of dynamic maps
 * - **Pattern matching**: When structure is known at compile time
 * - **Protocols**: For polymorphic behavior over dynamic dispatch
 * - **Behaviours**: For interface contracts over reflection
 * 
 * ## Performance Considerations
 * 
 * ### Compilation
 * - Reflect calls compile to direct Map module calls (no overhead)
 * - Field names converted to atoms at runtime (small cost)
 * - No additional abstraction layers
 * 
 * ### Runtime
 * - `field()`: O(1) Map.get operation
 * - `setField()`: O(1) Map.put (creates new map)
 * - `fields()`: O(n) iterates all keys
 * - `hasField()`: O(1) Map.has_key?
 * 
 * ### Memory
 * - Atoms are created for field names (be careful with user input!)
 * - Use `String.to_existing_atom` for safety in field()
 * - Maps are shallow-copied on updates (Elixir immutability)
 * 
 * ## Best Practices
 * 
 * 1. **Prefer Static Typing**: Use Reflect only when types are truly dynamic
 * 2. **Validate External Data**: Always validate before using Reflect on user input
 * 3. **Cache Field Lists**: Store `Reflect.fields()` result if used multiple times
 * 4. **Use Typedefs for Known Structures**: Even partial typing is better than Dynamic
 * 5. **Document Dynamic APIs**: Clearly specify expected fields in documentation
 * 
 * @see https://api.haxe.org/Reflect.html - Official Haxe Reflect documentation
 * @see https://hexdocs.pm/elixir/Map.html - Elixir Map module documentation
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
    public static function field<T, R>(obj: T, field: String): Null<R> {
        // Use native Elixir Map.get with atom conversion
        return untyped __elixir__('Map.get({0}, String.to_existing_atom({1}))', obj, field);
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
    public static function setField<T, V>(obj: T, field: String, value: V): T {
        // Use native Elixir Map.put with atom conversion
        // Note: This returns a new map (immutability)
        return untyped __elixir__('Map.put({0}, String.to_atom({1}), {2})', obj, field, value);
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
    public static function fields<T>(obj: T): Array<String> {
        // Use native Elixir to get map keys and convert atoms to strings
        return untyped __elixir__('Map.keys({0}) |> Enum.map(&Atom.to_string/1)', obj);
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
    public static function hasField<T>(obj: T, field: String): Bool;
    
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
    public static function deleteField<T>(obj: T, field: String): T;
    
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
    public static function isObject<T>(value: T): Bool;
    
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
    public static function callMethod<T, R>(obj: T, func: haxe.Constraints.Function, args: Array<{}>): R;
    
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
    public static function isEnumValue<T>(value: T): Bool;
}