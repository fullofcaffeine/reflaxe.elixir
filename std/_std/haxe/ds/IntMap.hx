package haxe.ds;

/**
 * IntMap extern (Elixir target)
 *
 * Declares the `haxe.ds.IntMap` API surface without emitting generated Elixir code.
 *
 * Runtime representation:
 * - `new IntMap()` compiles to an empty Elixir map (`%{}`) via `ConstructorBuilder`.
 * - Instance operations are lowered by the AST pipeline to native `Map.*` calls.
 */
@:nativeGen
extern class IntMap<T> implements haxe.Constraints.IMap<Int, T> {
	public function new():Void;
	public function set(key:Int, value:T):Void;
	public function get(key:Int):Null<T>;
	public function exists(key:Int):Bool;
	public function remove(key:Int):Bool;
	public function keys():Iterator<Int>;
	public function iterator():Iterator<T>;
	public function keyValueIterator():KeyValueIterator<Int, T>;
	public function copy():IntMap<T>;
	public function toString():String;
	public function clear():Void;
}
