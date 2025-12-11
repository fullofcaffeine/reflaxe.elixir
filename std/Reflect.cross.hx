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
//@:coreApi  // Commented out to allow Elixir-specific signatures for immutability
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
    public static function field(o: Dynamic, field: String): Dynamic {
        // Use native Elixir Map.get with atom conversion
        return untyped __elixir__('Map.get({0}, String.to_existing_atom({1}))', o, field);
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
    @:hack  // Override core API signature for Elixir immutability
    public static function setField(o: Dynamic, field: String, value: Dynamic): Dynamic {
        // Use native Elixir Map.put with atom conversion
        // Returns the new map (Elixir immutability)
        return untyped __elixir__('Map.put({0}, String.to_atom({1}), {2})', o, field, value);
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
    public static function fields(o: Dynamic): Array<String> {
        // Use native Elixir to get map keys and convert atoms to strings
        return untyped __elixir__('Map.keys({0}) |> Enum.map(&Atom.to_string/1)', o);
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
    public static function hasField(o: Dynamic, field: String): Bool {
        return untyped __elixir__('Map.has_key?({0}, String.to_existing_atom({1}))', o, field);
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
    @:hack  // Override core API signature for Elixir immutability
    public static function deleteField(o: Dynamic, field: String): Dynamic {
        // Use native Elixir Map.delete
        // Returns the new map without the field (Elixir immutability)
        return untyped __elixir__('Map.delete({0}, String.to_existing_atom({1}))', o, field);
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
    public static function isObject(v: Dynamic): Bool {
        // In Elixir, objects are maps
        return untyped __elixir__('is_map({0})', v);
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
    public static inline function copy<T>(o: T): T {
        // In Elixir, maps are immutable, so we just return the same map
        // This maintains API compatibility while being efficient
        return o;
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
	public static function callMethod(_o: Dynamic, func: haxe.Constraints.Function, args: Array<Dynamic>): Dynamic {
		// Elixir functions don't carry a `this` context; keep the object parameter
		// for API parity but only forward the provided arguments. Mark it used to
		// avoid compiler warnings when no context is needed.
		var _ignoreObj = _o;
		return untyped __elixir__('apply({0}, {1})', func, args);
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
        // Use string comparison and avoid early returns so the printer emits a
        // single expression (maps to `cond`/`if ... else ... end` in Elixir) and
        // preserves the final 0 fallback deterministically.
        // Avoid locals to prevent late passes from demoting them to underscores.
        return if (Std.string(a) < Std.string(b)) -1 else if (Std.string(a) > Std.string(b)) 1 else 0;
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
    public static function isEnumValue(v: Dynamic): Bool {
        // In Elixir, enums are represented as tagged tuples
        return untyped __elixir__('is_tuple({0}) and tuple_size({0}) >= 1 and is_atom(elem({0}, 0))', v);
    }
    
    /**
     * Check if a value is a function.
     * 
     * WHY: Type checking for dynamic function invocation and validation.
     * WHAT: Determines if a value can be called as a function.
     * HOW: In Elixir, checks if value is a function reference.
     * 
     * @param f The value to check
     * @return True if the value is a function
     */
    public static function isFunction(f: Dynamic): Bool {
        // In Elixir, check if it's a function
        // Use Kernel.is_function to avoid conflict with our own function name
        return untyped __elixir__('Kernel.is_function({0})', f);
    }
    
    /**
     * Compare two function references for equality.
     * 
     * WHY: Needed for checking if two function references point to the same function.
     * WHAT: Compares two function values for reference equality.
     * HOW: In Elixir, function references can be compared directly.
     * 
     * @param f1 First function to compare
     * @param f2 Second function to compare
     * @return True if both refer to the same function
     */
    public static function compareMethods(f1: Dynamic, f2: Dynamic): Bool {
        // In Elixir, function references can be compared directly
        return untyped __elixir__('{0} == {1}', f1, f2);
    }
    
    /**
     * Get a property value from an object.
     * 
     * WHY: Some platforms distinguish between fields and properties.
     * WHAT: Gets a property value (in Elixir, same as field).
     * HOW: In Elixir, properties and fields are the same (map keys).
     * 
     * @param o The object to get property from
     * @param field The property name
     * @return The property value
     */
    public static function getProperty(o: Dynamic, field: String): Dynamic {
        // In Elixir, properties are the same as fields
        // Note: We're calling Reflect.field function, not using the parameter directly
        return Reflect.field(o, field);
    }
    
    /**
     * Set a property value on an object.
     * 
     * WHY: Some platforms distinguish between fields and properties.
     * WHAT: Sets a property value (in Elixir, same as field).
     * HOW: In Elixir, properties and fields are the same (map keys).
     * 
     * @param o The object to set property on
     * @param field The property name
     * @param value The value to set
     */
    public static function setProperty(o: Dynamic, field: String, value: Dynamic): Void {
        // In Elixir, properties are the same as fields
        // Note: setField returns the new object, but setProperty returns Void
        setField(o, field, value);
    }
    
    /**
     * Create a variable argument function wrapper.
     * 
     * WHY: Needed for functions that accept variable number of arguments.
     * WHAT: Wraps a function to accept variable arguments.
     * HOW: Creates a wrapper that collects arguments into an array.
     * 
     * @param f Function that takes an array of arguments
     * @return Function that accepts variable arguments
     */
    public static function makeVarArgs(f: Array<Dynamic> -> Dynamic): Dynamic {
        // Create a function that collects arguments into an array
        return untyped __elixir__('fn args -> {0}.(args) end', f);
    }
}
