package elixir;

#if (macro || reflaxe_runtime)

/**
 * Enum module extern definitions for Elixir standard library
 * Provides type-safe interfaces for Enumerable operations
 * 
 * Maps to Elixir's Enum module functions with proper type signatures
 */
@:native("Enum")
extern class Enumerable {
    
    // Core mapping functions
    @:native("Enum.map") 
    public static function map<T, U>(enumerable: Array<T>, func: T -> U): Array<U>;
    
    @:native("Enum.filter")
    public static function filter<T>(enumerable: Array<T>, func: T -> Bool): Array<T>;
    
    @:native("Enum.reduce")
    public static function reduce<T, A>(enumerable: Array<T>, acc: A, func: (T, A) -> A): A;
    
    @:native("Enum.reduce")
    public static function reduceFromFirst<T>(enumerable: Array<T>, func: (T, T) -> T): Null<T>;
    
    // Aggregation functions
    @:native("Enum.count")
    public static function count<T>(enumerable: Array<T>): Int;
    
    @:native("Enum.count")
    public static function countWith<T>(enumerable: Array<T>, func: T -> Bool): Int;
    
    @:native("Enum.sum")
    public static function sum(enumerable: Array<Float>): Float;
    
    @:native("Enum.sum")
    public static function sumInt(enumerable: Array<Int>): Int;
    
    @:native("Enum.max")
    public static function max<T>(enumerable: Array<T>): Null<T>;
    
    @:native("Enum.min")
    public static function min<T>(enumerable: Array<T>): Null<T>;
    
    // Finding and membership
    @:native("Enum.find")
    public static function find<T>(enumerable: Array<T>, func: T -> Bool): Null<T>;
    
    @:native("Enum.find")
    public static function findWithDefault<T>(enumerable: Array<T>, defaultValue: T, func: T -> Bool): T;
    
    @:native("Enum.member?")
    public static function member<T>(enumerable: Array<T>, element: T): Bool;
    
    @:native("Enum.empty?")
    public static function empty<T>(enumerable: Array<T>): Bool;
    
    // Element access
    @:native("Enum.at")
    public static function at<T>(enumerable: Array<T>, index: Int): Null<T>;
    
    @:native("Enum.at")
    public static function atWithDefault<T>(enumerable: Array<T>, index: Int, defaultValue: T): T;
    
    @:native("Enum.fetch")
    public static function fetch<T>(enumerable: Array<T>, index: Int): {_0: String, _1: Null<T>}; // {:ok, value} | :error
    
    // List operations
    @:native("Enum.take")
    public static function take<T>(enumerable: Array<T>, amount: Int): Array<T>;
    
    @:native("Enum.drop")
    public static function drop<T>(enumerable: Array<T>, amount: Int): Array<T>;
    
    @:native("Enum.take_while")
    public static function takeWhile<T>(enumerable: Array<T>, func: T -> Bool): Array<T>;
    
    @:native("Enum.drop_while")
    public static function dropWhile<T>(enumerable: Array<T>, func: T -> Bool): Array<T>;
    
    // Sorting and grouping
    @:native("Enum.sort")
    public static function sort<T>(enumerable: Array<T>): Array<T>;
    
    @:native("Enum.sort")
    public static function sortBy<T, U>(enumerable: Array<T>, func: T -> U): Array<T>;
    
    @:native("Enum.sort")
    public static function sortWith<T>(enumerable: Array<T>, func: (T, T) -> String): Array<T>; // :lt, :eq, :gt
    
    @:native("Enum.reverse")
    public static function reverse<T>(enumerable: Array<T>): Array<T>;
    
    @:native("Enum.group_by")
    public static function groupBy<T, K>(enumerable: Array<T>, func: T -> K): haxe.ds.Map<K, Array<T>>;
    
    // Transformation
    @:native("Enum.flat_map")
    public static function flatMap<T, U>(enumerable: Array<T>, func: T -> Array<U>): Array<U>;
    
    @:native("Enum.concat")
    public static function concat<T>(enumerables: Array<Array<T>>): Array<T>;
    
    @:native("Enum.concat")
    public static function concatTwo<T>(left: Array<T>, right: Array<T>): Array<T>;
    
    @:native("Enum.uniq")
    public static function uniq<T>(enumerable: Array<T>): Array<T>;
    
    @:native("Enum.uniq_by")
    public static function uniqBy<T, U>(enumerable: Array<T>, func: T -> U): Array<T>;
    
    // Partitioning
    @:native("Enum.split")
    public static function split<T>(enumerable: Array<T>, amount: Int): {_0: Array<T>, _1: Array<T>};
    
    @:native("Enum.split_while")
    public static function splitWhile<T>(enumerable: Array<T>, func: T -> Bool): {_0: Array<T>, _1: Array<T>};
    
    @:native("Enum.partition")
    public static function partition<T>(enumerable: Array<T>, func: T -> Bool): {_0: Array<T>, _1: Array<T>};
    
    // Zipping
    @:native("Enum.zip")
    public static function zip<T, U>(left: Array<T>, right: Array<U>): Array<{_0: T, _1: U}>;
    
    @:native("Enum.zip")
    public static function zipMultiple(enumerables: Array<Array<Dynamic>>): Array<Array<Dynamic>>;
    
    @:native("Enum.with_index")
    public static function withIndex<T>(enumerable: Array<T>): Array<{_0: T, _1: Int}>;
    
    @:native("Enum.with_index")
    public static function withIndexFrom<T>(enumerable: Array<T>, offset: Int): Array<{_0: T, _1: Int}>;
    
    // Boolean operations
    @:native("Enum.all?")
    public static function all<T>(enumerable: Array<T>, func: T -> Bool): Bool;
    
    @:native("Enum.any?")
    public static function any<T>(enumerable: Array<T>, func: T -> Bool): Bool;
    
    // String joining
    @:native("Enum.join")
    public static function join<T>(enumerable: Array<T>): String;
    
    @:native("Enum.join")
    public static function joinWith<T>(enumerable: Array<T>, separator: String): String;
    
    // Advanced operations
    @:native("Enum.scan")
    public static function scan<T, A>(enumerable: Array<T>, acc: A, func: (T, A) -> A): Array<A>;
    
    @:native("Enum.chunk_by")
    public static function chunkBy<T, U>(enumerable: Array<T>, func: T -> U): Array<Array<T>>;
    
    @:native("Enum.chunk_every")
    public static function chunkEvery<T>(enumerable: Array<T>, count: Int): Array<Array<T>>;
    
    @:native("Enum.dedup")
    public static function dedup<T>(enumerable: Array<T>): Array<T>;
    
    @:native("Enum.dedup_by")
    public static function dedupBy<T, U>(enumerable: Array<T>, func: T -> U): Array<T>;
    
    @:native("Enum.into")
    public static function into<T>(enumerable: Array<T>, collectable: Array<T>): Array<T>;
}

#end