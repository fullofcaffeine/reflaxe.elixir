package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

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
    static function cycle<T>(enumerable: Array<T>): Term; // Infinite cycle of enumerable
    
    @:native("iterate")
    static function iterate<T>(start: T, next: T -> T): Term; // Infinite iteration
    
    @:native("repeatedly")
    static function repeatedly<T>(generator: Void -> T): Term; // Infinite repeated generation
    
    @:native("unfold")
    static function unfold<T, S>(initialValue: S, fn: S -> Null<{_0: T, _1: S}>): Term; // Unfold from seed
    
    @:native("resource")
    static function resource<T>(startup: Void -> Term, next: Term -> {_0: Array<T>, _1: Term}, shutdown: Term -> Void): Term;
    
    @:native("interval")
    static function interval(milliseconds: Int): Term; // Timer stream
    
    // Stream transformations
    @:native("map")
    static function map<T, R>(stream: Term, mapper: T -> R): Term;
    
    @:native("filter")
    static function filter<T>(stream: Term, predicate: T -> Bool): Term;
    
    @:native("reject")
    static function reject<T>(stream: Term, predicate: T -> Bool): Term;
    
    @:native("flat_map")
    static function flatMap<T, R>(stream: Term, mapper: T -> Array<R>): Term;
    
    @:native("take")
    static function take<T>(stream: Term, count: Int): Term;
    
    @:native("drop")
    static function drop<T>(stream: Term, count: Int): Term;
    
    @:native("take_while")
    static function takeWhile<T>(stream: Term, predicate: T -> Bool): Term;
    
    @:native("drop_while")
    static function dropWhile<T>(stream: Term, predicate: T -> Bool): Term;
    
    @:native("take_every")
    static function takeEvery<T>(stream: Term, nth: Int): Term;
    
    @:native("drop_every")
    static function dropEvery<T>(stream: Term, nth: Int): Term;
    
    @:native("chunk_every")
    static function chunkEvery<T>(stream: Term, count: Int): Term;
    
    @:native("chunk_every")
    static function chunkEveryWithStep<T>(stream: Term, count: Int, step: Int): Term;
    
    @:native("chunk_by")
    static function chunkBy<T, K>(stream: Term, fn: T -> K): Term;
    
    @:native("chunk_while")
    static function chunkWhile<T, S>(stream: Term, acc: S, chunkFn: T -> S -> Term, afterFn: S -> Term): Term;
    
    @:native("concat")
    static function concat(streams: Array<Term>): Term;
    
    @:native("concat")
    static function concatTwo(stream1: Term, stream2: Term): Term;
    
    @:native("dedupe")
    static function dedupe<T>(stream: Term): Term;
    
    @:native("dedupe_by")
    static function dedupeBy<T, K>(stream: Term, fn: T -> K): Term;
    
    @:native("uniq")
    static function uniq<T>(stream: Term): Term;
    
    @:native("uniq_by")
    static function uniqBy<T, K>(stream: Term, fn: T -> K): Term;
    
    // Zipping and windowing
    @:native("zip")
    static function zip(streams: Array<Term>): Term;
    
    @:native("zip")
    static function zipTwo(stream1: Term, stream2: Term): Term;
    
    @:native("zip_with")
    static function zipWith<T, R>(streams: Array<Term>, zipper: Array<T> -> R): Term;
    
    @:native("zip_with")
    static function zipWithTwo<T1, T2, R>(stream1: Term, stream2: Term, zipper: (T1, T2) -> R): Term;
    
    @:native("with_index")
    static function withIndex<T>(stream: Term, ?offset: Int): Term;
    
    // Scanning and transformation
    @:native("scan")
    static function scan<T, S>(stream: Term, acc: S, fn: (S, T) -> S): Term;
    
    @:native("transform")
    static function transform<T, S, R>(stream: Term, acc: S, fn: (S, T) -> {_0: Array<R>, _1: S}): Term;
    
    @:native("intersperse")
    static function intersperse<T>(stream: Term, separator: T): Term;
    
    // Stream execution
    @:native("run")
    static function run(stream: Term): Term; // Returns :ok
    
    @:native("into")
    static function into<T>(stream: Term, collectable: Term): Term;
    
    @:native("into")
    static function intoWithTransform<T, R>(stream: Term, collectable: Term, transform: T -> R): Term;
    
    // Helper functions for common operations
    public static inline function fromList<T>(list: Array<T>): Term {
        return untyped __elixir__('Stream.from_enumerable({0})', list);
    }
    
    public static inline function toList<T>(stream: Term): Array<T> {
        return untyped __elixir__('Enum.to_list({0})', stream);
    }
    
    public static inline function range(start: Int, stop: Int): Term {
        return untyped __elixir__('Stream.iterate({0}, &(&1 + 1)) |> Stream.take({1})', start, stop - start + 1);
    }
    
    public static inline function infiniteRange(start: Int, step: Int = 1): Term {
        return untyped __elixir__('Stream.iterate({0}, &(&1 + {1}))', start, step);
    }
    
    public static inline function lines(device: Null<Term> = null): Term {
        if (device == null) {
            return untyped __elixir__('IO.stream(:stdio, :line)');
        }
        return untyped __elixir__('IO.stream({0}, :line)', device);
    }
    
    public static inline function fileLines(path: String): Term {
        return untyped __elixir__('File.stream!({0})', path);
    }
    
    public static inline function each<T>(stream: Term, fn: T -> Void): Term {
        return untyped __elixir__('Stream.each({0}, {1}) |> Stream.run()', stream, fn);
    }
    
    public static inline function collect<T>(stream: Term): Array<T> {
        return toList(stream);
    }
    
    // Common stream patterns
    public static inline function numbers(from: Int = 0): Term {
        return infiniteRange(from, 1);
    }
    
    public static inline function fibonacci(): Term {
        return untyped __elixir__('Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)');
    }
    
    public static inline function random(min: Int = 0, max: Int = 100): Term {
        return untyped __elixir__('Stream.repeatedly(fn -> :rand.uniform({1} - {0} + 1) + {0} - 1 end)', min, max);
    }
}

/**
 * Stream composition utilities
 */
class StreamPipeline {
    private var stream: Term;
    
    public function new(source: Term) {
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
    
    public function run(): Term {
        return Stream.run(stream);
    }
    
    public function into<T>(collectable: Term): T {
        return cast Stream.into(stream, collectable);
    }
}

#end
