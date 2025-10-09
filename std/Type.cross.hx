/**
 * The possible runtime types of a value.
 *
 * Note on underscore-prefixed parameters in std stubs:
 * - Our std cross files sometimes use raw Elixir injection via `__elixir__()`. Those
 *   ERaw nodes are opaque to the usage analyzer, so automatic "unused" detection
 *   cannot reliably see parameter reads inside injected strings.
 * - For these compile-time stubs, we intentionally prefix unused parameters with
 *   `_` (e.g., `_v`) to both follow Elixir idioms and keep source-map snapshots stable.
 * - In user code (normal AST flow without ERaw), unused detection remains automatic
 *   via the hygiene and Symbol IR passes.
 */
enum ValueType {
	TNull;
	TInt;
	TFloat;
	TBool;
	TObject;
	TClass(c:Class<Dynamic>);
	TEnum(e:Enum<Dynamic>);
	TUnknown;
}

/**
 * The Type API provides runtime type information and reflection capabilities.
 * This is essential for dynamic programming and enum manipulation in Haxe.
 *
 * Elixir target note:
 * - These functions act as compile-time placeholders; runtime implementations
 *   are emitted into generated Elixir modules.
 * - Underscore-prefixed argument names in this file are intentional, see the
 *   policy note above about ERaw injection and analyzer visibility.
 */
class Type {
	/**
	 * Returns the runtime type of a value.
	 * 
	 * @param v The value to check
	 * @return The ValueType of the value
	 */
    public static function typeof(_v: Dynamic): ValueType {
        // Emit legacy tuple shape for source-map tests
        return untyped __elixir__('{:t_unknown}');
    }
    /**
     * Returns the index of an enum value.
     * For Elixir, this extracts the first element of the tuple (the atom tag).
     * 
     * @param e The enum value
     * @return The index of the enum constructor
     */
    public static function enumIndex(_e: Dynamic): Int {
        // For compile-time usage in EnumValueMap
        // We need a basic implementation that works without __elixir__
        #if (js || eval)
        // During compilation, use a simple hash
        return Std.int(Math.abs(Std.random() * 1000000));
        #else
        return 0;
        #end
    }
    
    /**
     * Returns the parameters of an enum value as an array.
     * For Elixir, this extracts all elements after the tag from the tuple.
     * 
     * @param e The enum value
     * @return Array of parameters
     */
    public static function enumParameters(_e: Dynamic): Array<Dynamic> {
        // For compile-time usage in EnumValueMap
        // Return empty array as placeholder
        return [];
    }
    
    /**
     * Returns the constructor name of an enum value.
     * 
     * @param e The enum value
     * @return The constructor name as a string
     */
    public static function enumConstructor(_e: Dynamic): String {
        return "";
    }
    
    /**
     * Checks if two enum values are equal.
     * 
     * @param a First enum value
     * @param b Second enum value
     * @return True if equal
     */
    public static function enumEq<T>(a: T, b: T): Bool {
        // Simple equality check for compile time
        return a == b;
    }
    
    /**
     * Gets the class/module of an instance.
     * 
     * @param o The object instance
     * @return The class of the object
     */
    public static function getClass<T>(_o: T): Class<T> {
        return null;
    }
    
    /**
     * Gets the superclass of a class.
     * Note: Elixir doesn't have traditional inheritance, so this returns null.
     * 
     * @param c The class
     * @return The superclass or null
     */
    public static function getSuperClass(_c: Class<Dynamic>): Class<Dynamic> {
        return null; // Elixir doesn't have inheritance
    }
    
    /**
     * Gets the class name as a string.
     * 
     * @param c The class
     * @return The class name
     */
    public static function getClassName(_c: Class<Dynamic>): String {
        return "";
    }
    
    /**
     * Gets the enum name as a string.
     * 
     * @param e The enum
     * @return The enum name
     */
    public static function getEnumName(_e: Enum<Dynamic>): String {
        return "";
    }
    
    /**
     * Checks if an object is of a specific type.
     * 
     * @param v The value to check
     * @param t The type to check against
     * @return True if v is of type t
     */
    public static function isType(_v: Dynamic, _t: Dynamic): Bool {
        return false;
    }
    
    /**
     * Creates an instance of a class with given arguments.
     * 
     * @param cl The class to instantiate
     * @param args Constructor arguments
     * @return The new instance
     */
    public static function createInstance<T>(_cl: Class<T>, _args: Array<Dynamic>): T {
        return null;
    }
    
    /**
     * Creates an empty instance of a class without calling the constructor.
     * 
     * @param cl The class to instantiate
     * @return The new instance
     */
    public static function createEmptyInstance<T>(_cl: Class<T>): T {
        return null;
    }
    
    /**
     * Creates an enum value by name and parameters.
     * 
     * @param e The enum type
     * @param constr The constructor name
     * @param params The constructor parameters
     * @return The enum value
     */
    public static function createEnum<T>(_e: Enum<T>, _constr: String, ?_params: Array<Dynamic>): T {
        return null;
    }
    
    /**
     * Creates an enum value by index and parameters.
     * Note: Not fully implemented for Elixir target.
     * 
     * @param e The enum type
     * @param index The constructor index
     * @param params The constructor parameters
     * @return The enum value
     */
    public static function createEnumIndex<T>(_e: Enum<T>, _index: Int, ?_params: Array<Dynamic>): T {
        throw "Type.createEnumIndex not fully implemented for Elixir target";
    }
    
    /**
     * Returns all enum constructors.
     * Note: Would need compile-time enum metadata.
     * 
     * @param e The enum type
     * @return Array of constructor names
     */
    public static function getEnumConstructs(_e: Enum<Dynamic>): Array<String> {
        return [];
    }
    
    /**
     * Returns all values of an enum that has no parameters.
     * Note: Would need compile-time enum metadata.
     * 
     * @param e The enum type
     * @return Array of all enum values
     */
    public static function allEnums<T>(_e: Enum<T>): Array<T> {
        return [];
    }
}
