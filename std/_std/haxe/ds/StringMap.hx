package haxe.ds;

/**
 * StringMap extern (Elixir target)
 *
 * Declares the `haxe.ds.StringMap` API surface without emitting generated Elixir code.
 *
 * Runtime representation:
 * - `new StringMap()` compiles to an empty Elixir map (`%{}`) via `ConstructorBuilder`.
 * - Instance operations are lowered by the AST pipeline to native `Map.*` calls.
 */
@:nativeGen
extern class StringMap<T> implements haxe.Constraints.IMap<String, T> {
	public function new():Void;
	public function set(key:String, value:T):Void;
	public function get(key:String):Null<T>;
	public function exists(key:String):Bool;
	public function remove(key:String):Bool;
	public function keys():Iterator<String>;
	public function iterator():Iterator<T>;
	public function keyValueIterator():KeyValueIterator<String, T>;
	public function copy():StringMap<T>;
	public function toString():String;
	public function clear():Void;
}
