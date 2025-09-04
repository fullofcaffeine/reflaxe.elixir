package elixir;

#if (macro || reflaxe_runtime)

/**
 * Stream module extern definitions for Elixir standard library
 * Provides type-safe interfaces for lazy enumeration operations
 * 
 * Maps to Elixir's Stream module functions with proper type signatures
 * Essential for memory-efficient processing of large or infinite sequences
 */
@:native("Stream")
extern class Stream {
    
    // Stream creation
    @:native("cycle")
    static function cycle<T>(enumerable: Array<T>): Dynamic; // Infinite cycle of enumerable
    
    @:native("iterate")
    static function iterate<T>(start: T, next: T -> T): Dynamic; // Infinite iteration
    
    @:native("repeatedly")
    static function repeatedly<T>(generator: Void -> T): Dynamic; // Infinite repeated generation
    
    @:native("unfold")
    static function unfold<T, S>(initialValue: S, fn: S -> Null<{_0: T, _1: S}>): Dynamic; // Unfold from seed
    
    @:native("resource")
    static function resource<T>(startup: Void -> Dynamic, next: Dynamic -> {_0: Array<T>, _1: Dynamic}, shutdown: Dynamic -> Void): Dynamic;
    
    @:native("interval")
    static function interval(milliseconds: Int): Dynamic; // Timer stream
    
    // Stream transformations
    @:native("map")
    static function map<T, R>(stream: Dynamic, mapper: T -> R): Dynamic;
    
    @:native("filter")
    static function filter<T>(stream: Dynamic, predicate: T -> Bool): Dynamic;
    
    @:native("reject")
    static function reject<T>(stream: Dynamic, predicate: T -> Bool): Dynamic;
    
    @:native("flat_map")
    static function flatMap<T, R>(stream: Dynamic, mapper: T -> Array<R>): Dynamic;
    
    @:native("take")
    static function take<T>(stream: Dynamic, count: Int): Dynamic;
    
    @:native("drop")
    static function drop<T>(stream: Dynamic, count: Int): Dynamic;
    
    @:native("take_while")
    static function takeWhile<T>(stream: Dynamic, predicate: T -> Bool): Dynamic;
    
    @:native("drop_while")
    static function dropWhile<T>(stream: Dynamic, predicate: T -> Bool): Dynamic;
    
    @:native("take_every")
    static function takeEvery<T>(stream: Dynamic, nth: Int): Dynamic;
    
    @:native("drop_every")
    static function dropEvery<T>(stream: Dynamic, nth: Int): Dynamic;
    
    @:native("chunk_every")
    static function chunkEvery<T>(stream: Dynamic, count: Int): Dynamic;
    
    @:native("chunk_every")
    static function chunkEveryWithStep<T>(stream: Dynamic, count: Int, step: Int): Dynamic;
    
    @:native("chunk_by")
    static function chunkBy<T, K>(stream: Dynamic, fn: T -> K): Dynamic;
    
    @:native("chunk_while")
    static function chunkWhile<T, S>(stream: Dynamic, acc: S, chunkFn: T -> S -> Dynamic, afterFn: S -> Dynamic): Dynamic;
    
    @:native("concat")
    static function concat(streams: Array<Dynamic>): Dynamic;
    
    @:native("concat")
    static function concatTwo(stream1: Dynamic, stream2: Dynamic): Dynamic;
    
    @:native("dedupe")
    static function dedupe<T>(stream: Dynamic): Dynamic;
    
    @:native("dedupe_by")
    static function dedupeBy<T, K>(stream: Dynamic, fn: T -> K): Dynamic;
    
    @:native("uniq")
    static function uniq<T>(stream: Dynamic): Dynamic;
    
    @:native("uniq_by")
    static function uniqBy<T, K>(stream: Dynamic, fn: T -> K): Dynamic;
    
    // Zipping and windowing
    @:native("zip")
    static function zip(streams: Array<Dynamic>): Dynamic;
    
    @:native("zip")
    static function zipTwo(stream1: Dynamic, stream2: Dynamic): Dynamic;
    
    @:native("zip_with")
    static function zipWith<T, R>(streams: Array<Dynamic>, zipper: Array<T> -> R): Dynamic;
    
    @:native("zip_with")
    static function zipWithTwo<T1, T2, R>(stream1: Dynamic, stream2: Dynamic, zipper: (T1, T2) -> R): Dynamic;
    
    @:native("with_index")
    static function withIndex<T>(stream: Dynamic, ?offset: Int): Dynamic;
    
    // Scanning and transformation
    @:native("scan")
    static function scan<T, S>(stream: Dynamic, acc: S, fn: (S, T) -> S): Dynamic;
    
    @:native("transform")
    static function transform<T, S, R>(stream: Dynamic, acc: S, fn: (S, T) -> {_0: Array<R>, _1: S}): Dynamic;
    
    @:native("intersperse")
    static function intersperse<T>(stream: Dynamic, separator: T): Dynamic;
    
    // Stream execution
    @:native("run")
    static function run(stream: Dynamic): String; // Returns :ok
    
    @:native("into")
    static function into<T>(stream: Dynamic, collectable: Dynamic): Dynamic;
    
    @:native("into")
    static function intoWithTransform<T, R>(stream: Dynamic, collectable: Dynamic, transform: T -> R): Dynamic;
    
    // Helper functions for common operations
    public static inline function fromList<T>(list: Array<T>): Dynamic {
        return untyped __elixir__('Stream.from_enumerable({0})', list);
    }
    
    public static inline function toList<T>(stream: Dynamic): Array<T> {
        return untyped __elixir__('Enum.to_list({0})', stream);
    }
    
    public static inline function range(start: Int, stop: Int): Dynamic {
        return untyped __elixir__('Stream.iterate({0}, &(&1 + 1)) |> Stream.take({1})', start, stop - start + 1);
    }
    
    public static inline function infiniteRange(start: Int, step: Int = 1): Dynamic {
        return untyped __elixir__('Stream.iterate({0}, &(&1 + {1}))', start, step);
    }
    
    public static inline function lines(device: Dynamic = null): Dynamic {
        if (device == null) {
            return untyped __elixir__('IO.stream(:stdio, :line)');
        }
        return untyped __elixir__('IO.stream({0}, :line)', device);
    }
    
    public static inline function fileLines(path: String): Dynamic {
        return untyped __elixir__('File.stream!({0})', path);
    }
    
    public static inline function each<T>(stream: Dynamic, fn: T -> Void): String {
        return untyped __elixir__('Stream.each({0}, {1}) |> Stream.run()', stream, fn);
    }
    
    public static inline function collect<T>(stream: Dynamic): Array<T> {
        return toList(stream);
    }
    
    // Common stream patterns
    public static inline function numbers(from: Int = 0): Dynamic {
        return infiniteRange(from, 1);
    }
    
    public static inline function fibonacci(): Dynamic {
        return untyped __elixir__('Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)');
    }
    
    public static inline function random(min: Int = 0, max: Int = 100): Dynamic {
        return untyped __elixir__('Stream.repeatedly(fn -> :rand.uniform({1} - {0} + 1) + {0} - 1 end)', min, max);
    }
}

/**
 * Stream composition utilities
 */
class StreamPipeline {
    private var stream: Dynamic;
    
    public function new(source: Dynamic) {
        this.stream = source;
    }
    
    public function map<T, R>(fn: T -> R): StreamPipeline {
        stream = Stream.map(stream, fn);
        return this;
    }
    
    public function filter<T>(fn: T -> Bool): StreamPipeline {
        stream = Stream.filter(stream, fn);
        return this;
    }
    
    public function take(n: Int): StreamPipeline {
        stream = Stream.take(stream, n);
        return this;
    }
    
    public function drop(n: Int): StreamPipeline {
        stream = Stream.drop(stream, n);
        return this;
    }
    
    public function dedupe(): StreamPipeline {
        stream = Stream.dedupe(stream);
        return this;
    }
    
    public function withIndex(offset: Int = 0): StreamPipeline {
        stream = Stream.withIndex(stream, offset);
        return this;
    }
    
    public function chunk(size: Int): StreamPipeline {
        stream = Stream.chunkEvery(stream, size);
        return this;
    }
    
    public function toList<T>(): Array<T> {
        return Stream.toList(stream);
    }
    
    public function run(): String {
        return Stream.run(stream);
    }
    
    public function into<T>(collectable: Dynamic): T {
        return Stream.into(stream, collectable);
    }
}

#end