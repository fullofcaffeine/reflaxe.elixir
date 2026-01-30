package haxe.ds;

/**
 * ObjectMap extern (Elixir target)
 *
 * Declares the `haxe.ds.ObjectMap` API surface without emitting generated Elixir code.
 *
 * NOTE
 * - The Elixir target primarily uses native maps for key/value storage. Object-keyed maps
 *   require careful semantic decisions (identity vs structural) and are treated as
 *   runtime-provided until stdlib parity work defines the exact behavior.
 */
@:nativeGen
extern class ObjectMap<K:{}, V> implements haxe.Constraints.IMap<K, V> {
    public function new(): Void;
    public function set(key: K, value: V): Void;
    public function get(key: K): Null<V>;
    public function exists(key: K): Bool;
    public function remove(key: K): Bool;
    public function keys(): Iterator<K>;
    public function iterator(): Iterator<V>;
    public function keyValueIterator(): KeyValueIterator<K, V>;
    public function copy(): ObjectMap<K, V>;
    public function toString(): String;
    public function clear(): Void;
}

