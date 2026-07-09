package haxe.iterators;

import haxe.Constraints.IMap;
import reflaxe.elixir.IMap as IMapRuntime;

/**
 * Elixir target runtime for `haxe.iterators.MapKeyValueIterator`.
 *
 * This keeps the canonical Haxe iterator API (`new/hasNext/next`) while using
 * process-local state internally so `next()` can advance without returning an
 * updated iterator value.
 *
 * Runtime input contract for `new(mapOrPairs)`:
 * - plain Elixir map (`%{}`), or
 * - list of `{key, value}` tuples / key-value maps.
 */
@:coreApi
class MapKeyValueIterator<K, V> {
	final pairs:Array<{key:K, value:V}>;
	final ref:Any;
	@:native("has_next") final hasNextFn:Void->Bool;
	@:native("next") final nextFn:Void->{key: K, value: V};
	var current:Int = 0;

	public function new(map:IMap<K, V>) {
		this.pairs = IMapRuntime.unwrap(map);
		this.ref = untyped __elixir__('make_ref()');
		this.hasNextFn = () -> hasNext();
		this.nextFn = () -> next();
	}

	function stateKey():Any {
		return untyped __elixir__('{__MODULE__, {0}}', this.ref);
	}

	function currentIndex():Int {
		return untyped __elixir__('Process.get({0}, {1})', stateKey(), this.current);
	}

	public function hasNext():Bool {
		return untyped __elixir__('{0} < length({1})', currentIndex(), this.pairs);
	}

	public function next():{key:K, value:V} {
		return untyped __elixir__('
            index = {0}
            Process.put({1}, index + 1)
            case Enum.at({2}, index) do
                %{key: key, value: value} -> %{key: key, value: value}
                {key, value} -> %{key: key, value: value}
                _ -> %{key: nil, value: nil}
            end
        ', currentIndex(), stateKey(), this.pairs);
	}
}
