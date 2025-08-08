package elixir;

#if (macro || reflaxe_runtime)

/**
 * List module extern definitions for Elixir standard library
 * Provides type-safe interfaces for List operations
 * 
 * Maps to Elixir's List module functions with proper type signatures
 */
@:native("List")
extern class List {
    
    // Basic list construction and deconstruction
    @:native("List.first")
    public static function first<T>(list: Array<T>): Null<T>;
    
    @:native("List.last")  
    public static function last<T>(list: Array<T>): Null<T>;
    
    @:native("List.wrap")
    public static function wrap<T>(term: Null<T>): Array<T>; // Wrap nil -> [], value -> [value], list -> list
    
    // List combination
    @:native("List.flatten")
    public static function flatten<T>(list: Array<Array<T>>): Array<T>;
    
    @:native("List.flatten")
    public static function flattenDeep(list: Array<Dynamic>): Array<Dynamic>; // Deep flatten any nesting
    
    @:native("List.duplicate")
    public static function duplicate<T>(element: T, n: Int): Array<T>;
    
    // List insertion and removal
    @:native("List.insert_at")
    public static function insertAt<T>(list: Array<T>, index: Int, value: T): Array<T>;
    
    @:native("List.replace_at")
    public static function replaceAt<T>(list: Array<T>, index: Int, value: T): Array<T>;
    
    @:native("List.update_at")
    public static function updateAt<T>(list: Array<T>, index: Int, func: T -> T): Array<T>;
    
    @:native("List.delete")
    public static function delete<T>(list: Array<T>, item: T): Array<T>;
    
    @:native("List.delete_at")
    public static function deleteAt<T>(list: Array<T>, index: Int): Array<T>;
    
    // List access and finding
    @:native("List.pop_at")
    public static function popAt<T>(list: Array<T>, index: Int): {_0: Null<T>, _1: Array<T>};
    
    @:native("List.pop_at")
    public static function popAtWithDefault<T>(list: Array<T>, index: Int, defaultValue: T): {_0: T, _1: Array<T>};
    
    // List folding (different from Enum.reduce for historical reasons)
    @:native("List.foldl")
    public static function foldl<T, A>(list: Array<T>, acc: A, func: (T, A) -> A): A;
    
    @:native("List.foldr")  
    public static function foldr<T, A>(list: Array<T>, acc: A, func: (T, A) -> A): A;
    
    // List keyed operations (for keyword lists / property lists)
    @:native("List.keydelete")
    public static function keydelete<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Array<{_0: K, _1: V}>;
    
    @:native("List.keyfind")
    public static function keyfind<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Null<{_0: K, _1: V}>;
    
    @:native("List.keymember?")
    public static function keymember<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Bool;
    
    @:native("List.keyreplace")
    public static function keyreplace<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int, tuple: {_0: K, _1: V}): Array<{_0: K, _1: V}>;
    
    @:native("List.keysort")
    public static function keysort<K, V>(list: Array<{_0: K, _1: V}>, position: Int): Array<{_0: K, _1: V}>;
    
    @:native("List.keystore")
    public static function keystore<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int, tuple: {_0: K, _1: V}): Array<{_0: K, _1: V}>;
    
    @:native("List.keytake")
    public static function keytake<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Null<{tuple: {_0: K, _1: V}, rest: Array<{_0: K, _1: V}>}>;
    
    // Zipping operations  
    @:native("List.zip")
    public static function zip<T, U>(list1: Array<T>, list2: Array<U>): Array<{_0: T, _1: U}>;
    
    @:native("List.unzip")
    public static function unzip<T, U>(list: Array<{_0: T, _1: U}>): {_0: Array<T>, _1: Array<U>};
    
    // String conversion (for charlists)
    @:native("List.to_string")
    public static function toString(charlist: Array<Int>): String; // Convert charlist to string
    
    @:native("List.to_charlist")  
    public static function toCharlist(string: String): Array<Int>; // Convert string to charlist
    
    @:native("List.to_atom")
    public static function toAtom(charlist: Array<Int>): String; // Convert charlist to atom (represented as string)
    
    @:native("List.to_existing_atom")
    public static function toExistingAtom(charlist: Array<Int>): String; // Convert to existing atom only
    
    @:native("List.to_float")
    public static function toFloat(charlist: Array<Int>): Float; // Convert charlist representation to float
    
    @:native("List.to_integer")
    public static function toInteger(charlist: Array<Int>): Int; // Convert charlist representation to integer
    
    @:native("List.to_integer")
    public static function toIntegerWithBase(charlist: Array<Int>, base: Int): Int;
    
    @:native("List.to_tuple")
    public static function toTuple<T>(list: Array<T>): Dynamic; // Convert to tuple (represented as Dynamic)
    
    // Improper lists (for advanced use cases)
    @:native("List.improper?")  
    public static function improper<T>(list: Array<T>): Bool;
    
    // List comprehension helpers (complementary to Enum)
    @:native("List.myers_difference")
    public static function myersDifference<T>(list1: Array<T>, list2: Array<T>): Array<{_0: String, _1: Array<T>}>; // [:eq | :ins | :del, elements]
}

#end