package elixir;

#if (macro || reflaxe_runtime)

/**
 * Enum module extern definitions for Elixir standard library
 * Provides type-safe interfaces for enumerable operations
 * 
 * Maps to Elixir's Enum module functions with proper type signatures
 * Essential for list processing, data transformation, and functional programming patterns
 */
@:native("Enum")
extern class Enum {
    
    // Basic enumeration operations
    @:native("Enum.count")
    public static function count(enumerable: Dynamic): Int; // Count elements
    
    @:native("Enum.count")
    public static function countWith(enumerable: Dynamic, predicate: Dynamic -> Bool): Int; // Count matching elements
    
    @:native("Enum.empty?")
    public static function empty(enumerable: Dynamic): Bool; // Check if empty
    
    @:native("Enum.member?")
    public static function member(enumerable: Dynamic, element: Dynamic): Bool; // Check membership
    
    // Element access and retrieval
    @:native("Enum.at")
    public static function at(enumerable: Dynamic, index: Int): Dynamic; // Get element at index
    
    @:native("Enum.at")
    public static function atWithDefault(enumerable: Dynamic, index: Int, defaultValue: Dynamic): Dynamic;
    
    @:native("Enum.fetch")
    public static function fetch(enumerable: Dynamic, index: Int): {_0: String, _1: Dynamic}; // {:ok, element} | :error
    
    @:native("Enum.fetch!")
    public static function fetchBang(enumerable: Dynamic, index: Int): Dynamic; // Get element or raise
    
    @:native("Enum.find")
    public static function find(enumerable: Dynamic, predicate: Dynamic -> Bool): Null<Dynamic>; // Find first match
    
    @:native("Enum.find")
    public static function findWithDefault(enumerable: Dynamic, defaultValue: Dynamic, predicate: Dynamic -> Bool): Dynamic;
    
    @:native("Enum.find_value")
    public static function findValue(enumerable: Dynamic, predicate: Dynamic -> Dynamic): Null<Dynamic>; // Find and transform
    
    @:native("Enum.find_index")
    public static function findIndex(enumerable: Dynamic, predicate: Dynamic -> Bool): Null<Int>; // Find index of match
    
    // Collection transformation
    @:native("Enum.map")
    public static function map<T, R>(enumerable: Array<T>, mapper: T -> R): Array<R>; // Transform elements
    
    @:native("Enum.map_every")
    public static function mapEvery<T>(enumerable: Array<T>, nth: Int, mapper: T -> T): Array<T>; // Map every nth element
    
    @:native("Enum.map_join")
    public static function mapJoin<T>(enumerable: Array<T>, joiner: String, mapper: T -> String): String; // Map and join
    
    @:native("Enum.map_reduce")
    public static function mapReduce<T, R, A>(enumerable: Array<T>, accumulator: A, mapper: T -> A -> {_0: R, _1: A}): {_0: Array<R>, _1: A};
    
    @:native("Enum.flat_map")
    public static function flatMap<T, R>(enumerable: Array<T>, mapper: T -> Array<R>): Array<R>; // Map and flatten
    
    @:native("Enum.flat_map_reduce")
    public static function flatMapReduce<T, R, A>(enumerable: Array<T>, accumulator: A, mapper: T -> A -> {_0: Array<R>, _1: A}): {_0: Array<R>, _1: A};
    
    // Filtering operations
    @:native("Enum.filter")
    public static function filter<T>(enumerable: Array<T>, predicate: T -> Bool): Array<T>; // Keep matching elements
    
    @:native("Enum.reject")
    public static function reject<T>(enumerable: Array<T>, predicate: T -> Bool): Array<T>; // Remove matching elements
    
    @:native("Enum.split_with")
    public static function splitWith<T>(enumerable: Array<T>, predicate: T -> Bool): {_0: Array<T>, _1: Array<T>}; // Split by predicate
    
    @:native("Enum.partition")
    public static function partition<T>(enumerable: Array<T>, predicate: T -> Bool): {_0: Array<T>, _1: Array<T>}; // Alias for split_with
    
    // Reduction operations
    @:native("Enum.reduce")
    public static function reduce<T, A>(enumerable: Array<T>, accumulator: A, reducer: A -> T -> A): A; // Fold left
    
    @:native("Enum.reduce")
    public static function reduceWithoutAccumulator<T>(enumerable: Array<T>, reducer: T -> T -> T): T; // Reduce with first element as acc
    
    @:native("Enum.reduce_while")
    public static function reduceWhile<T, A>(enumerable: Array<T>, accumulator: A, reducer: A -> T -> {_0: String, _1: A}): A; // Reduce with halt/cont
    
    @:native("Enum.scan")
    public static function scan<T, A>(enumerable: Array<T>, accumulator: A, scanner: A -> T -> A): Array<A>; // Intermediate results
    
    @:native("Enum.scan")
    public static function scanWithoutAccumulator<T>(enumerable: Array<T>, scanner: T -> T -> T): Array<T>;
    
    // Aggregation functions
    @:native("Enum.sum")
    public static function sum(enumerable: Dynamic): Dynamic; // Sum numeric values
    
    @:native("Enum.product")
    public static function product(enumerable: Dynamic): Dynamic; // Product of numeric values
    
    @:native("Enum.max")
    public static function max(enumerable: Dynamic): Dynamic; // Maximum element
    
    @:native("Enum.max")
    public static function maxWithDefault(enumerable: Dynamic, defaultValue: Dynamic): Dynamic;
    
    @:native("Enum.max_by")
    public static function maxBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): T; // Max by transformation
    
    @:native("Enum.min")
    public static function min(enumerable: Dynamic): Dynamic; // Minimum element
    
    @:native("Enum.min")
    public static function minWithDefault(enumerable: Dynamic, defaultValue: Dynamic): Dynamic;
    
    @:native("Enum.min_by")
    public static function minBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): T; // Min by transformation
    
    @:native("Enum.min_max")
    public static function minMax(enumerable: Dynamic): {_0: Dynamic, _1: Dynamic}; // {min, max}
    
    @:native("Enum.min_max_by")
    public static function minMaxBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): {_0: T, _1: T};
    
    // List manipulation
    @:native("Enum.take")
    public static function take<T>(enumerable: Array<T>, amount: Int): Array<T>; // Take first n elements
    
    @:native("Enum.take_every")
    public static function takeEvery<T>(enumerable: Array<T>, nth: Int): Array<T>; // Take every nth element
    
    @:native("Enum.take_random")
    public static function takeRandom<T>(enumerable: Array<T>, count: Int): Array<T>; // Take random elements
    
    @:native("Enum.take_while")
    public static function takeWhile<T>(enumerable: Array<T>, predicate: T -> Bool): Array<T>; // Take while condition true
    
    @:native("Enum.drop")
    public static function drop<T>(enumerable: Array<T>, amount: Int): Array<T>; // Skip first n elements
    
    @:native("Enum.drop_every")
    public static function dropEvery<T>(enumerable: Array<T>, nth: Int): Array<T>; // Drop every nth element
    
    @:native("Enum.drop_while")
    public static function dropWhile<T>(enumerable: Array<T>, predicate: T -> Bool): Array<T>; // Drop while condition true
    
    @:native("Enum.slice")
    public static function slice<T>(enumerable: Array<T>, start: Int, amount: Int): Array<T>; // Extract slice
    
    @:native("Enum.split")
    public static function split<T>(enumerable: Array<T>, count: Int): {_0: Array<T>, _1: Array<T>}; // Split at position
    
    // Sorting operations
    @:native("Enum.sort")
    public static function sort<T>(enumerable: Array<T>): Array<T>; // Sort elements
    
    @:native("Enum.sort")
    public static function sortWith<T>(enumerable: Array<T>, sorter: T -> T -> String): Array<T>; // Custom sort (:lt, :eq, :gt)
    
    @:native("Enum.sort_by")
    public static function sortBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): Array<T>; // Sort by transformation
    
    @:native("Enum.sort_by")
    public static function sortByWith<T>(enumerable: Array<T>, mapper: T -> Dynamic, sorter: Dynamic -> Dynamic -> String): Array<T>;
    
    // List operations
    @:native("Enum.reverse")
    public static function reverse<T>(enumerable: Array<T>): Array<T>; // Reverse order
    
    @:native("Enum.shuffle")
    public static function shuffle<T>(enumerable: Array<T>): Array<T>; // Random shuffle
    
    @:native("Enum.random")
    public static function random<T>(enumerable: Array<T>): T; // Random element
    
    @:native("Enum.uniq")
    public static function uniq<T>(enumerable: Array<T>): Array<T>; // Remove duplicates
    
    @:native("Enum.uniq_by")
    public static function uniqBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): Array<T>; // Unique by transformation
    
    @:native("Enum.frequencies")
    public static function frequencies<T>(enumerable: Array<T>): Map<T, Int>; // Count occurrences
    
    @:native("Enum.frequencies_by")
    public static function frequenciesBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): Map<Dynamic, Int>;
    
    // Set operations
    @:native("Enum.dedup")
    public static function dedup<T>(enumerable: Array<T>): Array<T>; // Remove consecutive duplicates
    
    @:native("Enum.dedup_by")
    public static function dedupBy<T>(enumerable: Array<T>, mapper: T -> Dynamic): Array<T>;
    
    // Joining and concatenation
    @:native("Enum.join")
    public static function join(enumerable: Dynamic): String; // Join to string
    
    @:native("Enum.join")
    public static function joinWith(enumerable: Dynamic, joiner: String): String; // Join with separator
    
    @:native("Enum.concat")
    public static function concat(enumerables: Array<Dynamic>): Dynamic; // Concatenate multiple enumerables
    
    @:native("Enum.concat")
    public static function concatTwo(left: Dynamic, right: Dynamic): Dynamic; // Concatenate two enumerables
    
    // Chunking operations
    @:native("Enum.chunk_every")
    public static function chunkEvery<T>(enumerable: Array<T>, count: Int): Array<Array<T>>; // Chunk into fixed sizes
    
    @:native("Enum.chunk_every")
    public static function chunkEveryWithStep<T>(enumerable: Array<T>, count: Int, step: Int): Array<Array<T>>;
    
    @:native("Enum.chunk_by")
    public static function chunkBy<T>(enumerable: Array<T>, chunker: T -> Dynamic): Array<Array<T>>; // Chunk by transformation
    
    @:native("Enum.chunk_while")
    public static function chunkWhile<T, A>(enumerable: Array<T>, acc: A, chunker: T -> A -> {_0: String, _1: A}): Array<Array<T>>;
    
    // Validation operations
    @:native("Enum.all?")
    public static function all(enumerable: Dynamic): Bool; // All truthy
    
    @:native("Enum.all?")
    public static function allWith(enumerable: Dynamic, predicate: Dynamic -> Bool): Bool; // All match predicate
    
    @:native("Enum.any?")
    public static function any(enumerable: Dynamic): Bool; // Any truthy
    
    @:native("Enum.any?")
    public static function anyWith(enumerable: Dynamic, predicate: Dynamic -> Bool): Bool; // Any match predicate
    
    // Zipping operations
    @:native("Enum.zip")
    public static function zip<T, R>(left: Array<T>, right: Array<R>): Array<{_0: T, _1: R}>; // Zip two enumerables
    
    @:native("Enum.zip")
    public static function zipMultiple(enumerables: Array<Dynamic>): Array<Array<Dynamic>>; // Zip multiple enumerables
    
    @:native("Enum.zip_with")
    public static function zipWith<T, R, S>(left: Array<T>, right: Array<R>, zipper: T -> R -> S): Array<S>; // Zip with transformation
    
    @:native("Enum.zip_reduce")
    public static function zipReduce<T, R, A>(left: Array<T>, right: Array<R>, acc: A, reducer: T -> R -> A -> A): A;
    
    @:native("Enum.unzip")
    public static function unzip<T, R>(enumerable: Array<{_0: T, _1: R}>): {_0: Array<T>, _1: Array<R>}; // Unzip pairs
    
    // Interspersion
    @:native("Enum.intersperse")
    public static function intersperse<T>(enumerable: Array<T>, separator: T): Array<T>; // Insert separator between elements
    
    // Conversion operations
    @:native("Enum.to_list")
    public static function toList<T>(enumerable: Dynamic): Array<T>; // Convert to list
    
    @:native("Enum.into")
    public static function into<T>(enumerable: Array<T>, collectable: Dynamic): Dynamic; // Convert into collection
    
    @:native("Enum.into")
    public static function intoWithTransform<T>(enumerable: Array<T>, collectable: Dynamic, transform: T -> Dynamic): Dynamic;
    
    // Helper functions for common patterns
    public static inline function forEach<T>(enumerable: Array<T>, action: T -> Void): Array<T> {
        map(enumerable, (item) -> { action(item); return item; });
        return enumerable;
    }
    
    public static inline function exists<T>(enumerable: Array<T>, predicate: T -> Bool): Bool {
        return anyWith(enumerable, predicate);
    }
    
    public static inline function contains<T>(enumerable: Array<T>, element: T): Bool {
        return member(enumerable, element);
    }
    
    public static inline function isEmpty<T>(enumerable: Array<T>): Bool {
        return empty(enumerable);
    }
    
    public static inline function size<T>(enumerable: Array<T>): Int {
        return count(enumerable);
    }
    
    public static inline function first<T>(enumerable: Array<T>): Null<T> {
        return at(enumerable, 0);
    }
    
    public static inline function last<T>(enumerable: Array<T>): Null<T> {
        var len = count(enumerable);
        return len > 0 ? at(enumerable, len - 1) : null;
    }
    
    public static inline function head<T>(enumerable: Array<T>): Null<T> {
        return first(enumerable);
    }
    
    public static inline function tail<T>(enumerable: Array<T>): Array<T> {
        return drop(enumerable, 1);
    }
    
    public static inline function second<T>(enumerable: Array<T>): Null<T> {
        return at(enumerable, 1);
    }
    
    public static inline function third<T>(enumerable: Array<T>): Null<T> {
        return at(enumerable, 2);
    }
    
    // Common functional programming patterns
    public static inline function foldLeft<T, A>(enumerable: Array<T>, accumulator: A, folder: A -> T -> A): A {
        return reduce(enumerable, accumulator, folder);
    }
    
    public static inline function collect<T, R>(enumerable: Array<T>, collector: T -> R): Array<R> {
        return map(enumerable, collector);
    }
    
    public static inline function select<T>(enumerable: Array<T>, selector: T -> Bool): Array<T> {
        return filter(enumerable, selector);
    }
    
    public static inline function where<T>(enumerable: Array<T>, predicate: T -> Bool): Array<T> {
        return filter(enumerable, predicate);
    }
}

#end