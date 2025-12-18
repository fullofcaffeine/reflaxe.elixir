package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * List module extern definitions for Elixir standard library
 * Provides type-safe interfaces for List operations
 * 
 * Maps to Elixir's List module functions with proper type signatures
 */
@:native("List")
extern class List {
    
    // Basic list construction and deconstruction
    @:native("first")
    public static function first<T>(list: Array<T>): Null<T>;
    
    @:native("last")  
    public static function last<T>(list: Array<T>): Null<T>;
    
    @:native("wrap")
    public static function wrap<T>(term: Null<T>): Array<T>; // Wrap nil -> [], value -> [value], list -> list
    
    // List combination
    @:native("flatten")
    public static function flatten<T>(list: Array<Array<T>>): Array<T>;
    
    @:native("flatten")
    public static function flattenDeep(list: Array<Term>): Array<Term>; // Deep flatten any nesting
    
    @:native("duplicate")
    public static function duplicate<T>(element: T, n: Int): Array<T>;
    
    // List insertion and removal
    @:native("insert_at")
    public static function insertAt<T>(list: Array<T>, index: Int, value: T): Array<T>;
    
    @:native("replace_at")
    public static function replaceAt<T>(list: Array<T>, index: Int, value: T): Array<T>;
    
    @:native("update_at")
    public static function updateAt<T>(list: Array<T>, index: Int, func: T -> T): Array<T>;
    
    @:native("delete")
    public static function delete<T>(list: Array<T>, item: T): Array<T>;
    
    @:native("delete_at")
    public static function deleteAt<T>(list: Array<T>, index: Int): Array<T>;
    
    // List access and finding
    @:native("pop_at")
    public static function popAt<T>(list: Array<T>, index: Int): {_0: Null<T>, _1: Array<T>};
    
    @:native("pop_at")
    public static function popAtWithDefault<T>(list: Array<T>, index: Int, defaultValue: T): {_0: T, _1: Array<T>};
    
    // List folding (different from Enum.reduce for historical reasons)
    @:native("foldl")
    public static function foldl<T, A>(list: Array<T>, acc: A, func: (T, A) -> A): A;
    
    @:native("foldr")  
    public static function foldr<T, A>(list: Array<T>, acc: A, func: (T, A) -> A): A;
    
    // List keyed operations (for keyword lists / property lists)
    @:native("keydelete")
    public static function keydelete<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Array<{_0: K, _1: V}>;
    
    @:native("keyfind")
    public static function keyfind<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Null<{_0: K, _1: V}>;
    
    @:native("keymember?")
    public static function keymember<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Bool;
    
    @:native("keyreplace")
    public static function keyreplace<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int, tuple: {_0: K, _1: V}): Array<{_0: K, _1: V}>;
    
    @:native("keysort")
    public static function keysort<K, V>(list: Array<{_0: K, _1: V}>, position: Int): Array<{_0: K, _1: V}>;
    
    @:native("keystore")
    public static function keystore<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int, tuple: {_0: K, _1: V}): Array<{_0: K, _1: V}>;
    
    @:native("keytake")
    public static function keytake<K, V>(list: Array<{_0: K, _1: V}>, key: K, position: Int): Null<{tuple: {_0: K, _1: V}, rest: Array<{_0: K, _1: V}>}>;
    
    // Zipping operations  
    @:native("zip")
    public static function zip<T, U>(list1: Array<T>, list2: Array<U>): Array<{_0: T, _1: U}>;
    
    @:native("unzip")
    public static function unzip<T, U>(list: Array<{_0: T, _1: U}>): {_0: Array<T>, _1: Array<U>};
    
    // String conversion (for charlists)
    @:native("to_string")
    public static function toString(charlist: Array<Int>): String; // Convert charlist to string
    
    @:native("to_charlist")  
    public static function toCharlist(string: String): Array<Int>; // Convert string to charlist
    
    @:native("to_atom")
    public static function toAtom(charlist: Array<Int>): String; // Convert charlist to atom (represented as string)
    
    @:native("to_existing_atom")
    public static function toExistingAtom(charlist: Array<Int>): String; // Convert to existing atom only
    
    @:native("to_float")
    public static function toFloat(charlist: Array<Int>): Float; // Convert charlist representation to float
    
    @:native("to_integer")
    public static function toInteger(charlist: Array<Int>): Int; // Convert charlist representation to integer
    
    @:native("to_integer")
    public static function toIntegerWithBase(charlist: Array<Int>, base: Int): Int;
    
    @:native("to_tuple")
    public static function toTuple<T>(list: Array<T>): Term; // Convert to tuple
    
    // Improper lists (for advanced use cases)
    @:native("improper?")  
    public static function improper<T>(list: Array<T>): Bool;
    
    // List comprehension helpers (complementary to Enum)
    @:native("List.myers_difference")
    public static function myersDifference<T>(list1: Array<T>, list2: Array<T>): Array<{_0: String, _1: Array<T>}>; // [:eq | :ins | :del, elements]
}

#end
