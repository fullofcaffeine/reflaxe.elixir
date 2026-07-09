package haxe.ds;

/**
 * ObjectMap extern (Elixir target)
 *
 * Declares the `haxe.ds.ObjectMap` API surface without emitting generated Elixir code.
 *
 * NOTE
 * - The Elixir target rejects ObjectMap for output code until it has a real identity-key
 *   implementation. Native BEAM maps compare keys structurally, while Haxe ObjectMap
 *   requires object-identity semantics.
 *
 * `@:nativeGen` marks this extern as a target-native declaration: it provides the Haxe
 * type/API surface without asking Reflaxe.Elixir to emit a generated `ObjectMap` class.
 * Constructors and method calls are still handled by the compiler pipeline, which currently
 * rejects them with the identity-semantics error instead of lowering to an incorrect BEAM map.
 */
@:nativeGen
extern class ObjectMap<K:{}, V> implements haxe.Constraints.IMap<K, V> {
	public function new():Void;
	public function set(key:K, value:V):Void;
	public function get(key:K):Null<V>;
	public function exists(key:K):Bool;
	public function remove(key:K):Bool;
	public function keys():Iterator<K>;
	public function iterator():Iterator<V>;
	public function keyValueIterator():KeyValueIterator<K, V>;
	public function copy():ObjectMap<K, V>;
	public function toString():String;
	public function clear():Void;
}
