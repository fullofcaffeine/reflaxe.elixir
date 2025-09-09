/**
 * The possible runtime types of a value.
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
 * For the Elixir target, these functions use simple placeholders during compilation
 * and are properly implemented in the generated Elixir runtime code.
 */
class Type {
	/**
	 * Returns the runtime type of a value.
	 * 
	 * @param v The value to check
	 * @return The ValueType of the value
	 */
	public static function typeof(v: Dynamic): ValueType {
		// Placeholder implementation for compile time
		// The real implementation is in Type.ex
		return TUnknown;
	}
    /**
     * Returns the index of an enum value.
     * For Elixir, this extracts the first element of the tuple (the atom tag).
     * 
     * @param e The enum value
     * @return The index of the enum constructor
     */
    public static function enumIndex(e: Dynamic): Int {
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
    public static function enumParameters(e: Dynamic): Array<Dynamic> {
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
    public static function enumConstructor(e: Dynamic): String {
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
    public static function getClass<T>(o: T): Class<T> {
        return null;
    }
    
    /**
     * Gets the superclass of a class.
     * Note: Elixir doesn't have traditional inheritance, so this returns null.
     * 
     * @param c The class
     * @return The superclass or null
     */
    public static function getSuperClass(c: Class<Dynamic>): Class<Dynamic> {
        return null; // Elixir doesn't have inheritance
    }
    
    /**
     * Gets the class name as a string.
     * 
     * @param c The class
     * @return The class name
     */
    public static function getClassName(c: Class<Dynamic>): String {
        return "";
    }
    
    /**
     * Gets the enum name as a string.
     * 
     * @param e The enum
     * @return The enum name
     */
    public static function getEnumName(e: Enum<Dynamic>): String {
        return "";
    }
    
    /**
     * Checks if an object is of a specific type.
     * 
     * @param v The value to check
     * @param t The type to check against
     * @return True if v is of type t
     */
    public static function isType(v: Dynamic, t: Dynamic): Bool {
        return false;
    }
    
    /**
     * Creates an instance of a class with given arguments.
     * 
     * @param cl The class to instantiate
     * @param args Constructor arguments
     * @return The new instance
     */
    public static function createInstance<T>(cl: Class<T>, args: Array<Dynamic>): T {
        return null;
    }
    
    /**
     * Creates an empty instance of a class without calling the constructor.
     * 
     * @param cl The class to instantiate
     * @return The new instance
     */
    public static function createEmptyInstance<T>(cl: Class<T>): T {
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
    public static function createEnum<T>(e: Enum<T>, constr: String, ?params: Array<Dynamic>): T {
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
    public static function createEnumIndex<T>(e: Enum<T>, index: Int, ?params: Array<Dynamic>): T {
        throw "Type.createEnumIndex not fully implemented for Elixir target";
    }
    
    /**
     * Returns all enum constructors.
     * Note: Would need compile-time enum metadata.
     * 
     * @param e The enum type
     * @return Array of constructor names
     */
    public static function getEnumConstructs(e: Enum<Dynamic>): Array<String> {
        return [];
    }
    
    /**
     * Returns all values of an enum that has no parameters.
     * Note: Would need compile-time enum metadata.
     * 
     * @param e The enum type
     * @return Array of all enum values
     */
    public static function allEnums<T>(e: Enum<T>): Array<T> {
        return [];
    }
}