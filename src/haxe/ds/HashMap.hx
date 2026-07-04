package haxe.ds;

import haxe.Constraints.IMap;
import elixir.types.Term;

/**
 * HashMap (Elixir target)
 *
 * WHAT
 * - BEAM-safe implementation of canonical `haxe.ds.HashMap`.
 *
 * WHY
 * - Upstream `HashMap` stores keys and values in `IntMap` instances keyed by
 *   `key.hashCode()`. On this target `IntMap` is an extern surface lowered to
 *   native Elixir maps, so emitting the upstream helper class would call
 *   nonexistent `IntMap` runtime modules from generated Elixir.
 *
 * HOW
 * - Store entries in one immutable Elixir map: `hashCode() -> %{key, value}`.
 * - Mutating methods return updated receiver state through
 *   `ReceiverReturnConventions`, so callers rebind the persistent receiver in
 *   the same Elixir scope.
 * - Iterators expose closure-backed Haxe iterator maps, matching the native map
 *   iterator runtime shape already used by this target.
 *
 * EXAMPLES
 * ```haxe
 * var map = new HashMap<Key, String>();
 * map.set(key, "value");
 * map.get(key); // "value"
 * ```
 */
class HashMap<K:{function hashCode():Int;}, V> implements IMap<K, V> {
	var entries:Term;

	public function new(?entries:Term) {
		this.entries = entries == null ? untyped __elixir__("%{}") : entries;
	}

	public function set(k:K, v:V):Void {
		entries = untyped __elixir__("Map.put({0}, {1}, %{key: {2}, value: {3}})", entries, hash(k), k, v);
	}

	public function get(k:K):Null<V> {
		return untyped __elixir__('
			case Map.get({0}, {1}) do
			  nil -> nil
			  %{value: value} -> value
			end
		', entries, hash(k));
	}

	public function exists(k:K):Bool {
		return untyped __elixir__("Map.has_key?({0}, {1})", entries, hash(k));
	}

	public function remove(k:K):Bool {
		var result:Term = untyped __elixir__('
			hash = {1}
			{Map.delete({0}, hash), Map.has_key?({0}, hash)}
		', entries, hash(k));
		entries = untyped __elixir__("elem({0}, 0)", result);
		return untyped __elixir__("elem({0}, 1)", result);
	}

	public function keys():Iterator<K> {
		return cast iteratorFromList(untyped __elixir__('
			{0}
			|> Map.values()
			|> Enum.map(fn %{key: key} -> key end)
		', entries));
	}

	public function iterator():Iterator<V> {
		return cast iteratorFromList(untyped __elixir__('
			{0}
			|> Map.values()
			|> Enum.map(fn %{value: value} -> value end)
		', entries));
	}

	public function keyValueIterator():KeyValueIterator<K, V> {
		return cast iteratorFromList(untyped __elixir__('
			{0}
			|> Map.values()
			|> Enum.map(fn %{key: key, value: value} -> %{key: key, value: value} end)
		', entries));
	}

	public function copy():IMap<K, V> {
		return new HashMap<K, V>(entries);
	}

	public function toString():String {
		return untyped __elixir__('
			{0}
			|> Map.values()
			|> Enum.map(fn %{key: key, value: value} ->
			  Std.string(key) <> " => " <> Std.string(value)
			end)
			|> Enum.join(", ")
			|> then(fn body -> "{" <> body <> "}" end)
		', entries);
	}

	public function clear():Void {
		entries = untyped __elixir__("%{}");
	}

	static function hash<K:{function hashCode():Int;}>(key:K):Int {
		return untyped __elixir__("apply(Map.get({0}, :__reflaxe_class__) || Map.get({0}, :__struct__), :hash_code, [{0}])", key);
	}

	static function iteratorFromList<T>(values:Array<T>):Iterator<T> {
		return cast untyped __elixir__('
			ref = make_ref()
			state_key = {HashMapIterator, ref}
			%{
			  ref: ref,
			  current: 0,
			  has_next: fn ->
			    Process.get(state_key, 0) < length({0})
			  end,
			  next: fn ->
			    index = Process.get(state_key, 0)
			    Process.put(state_key, index + 1)
			    Enum.at({0}, index)
			  end
			}
		', values);
	}
}
