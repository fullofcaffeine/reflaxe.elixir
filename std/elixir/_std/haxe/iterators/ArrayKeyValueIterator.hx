package haxe.iterators;

/**
 * Elixir target runtime for explicit array key/value iterator construction.
 *
 * Normal `for (i => value in array)` loops are lowered directly to
 * `Enum.with_index/1`, but stdlib containers such as `haxe.ds.List` can expose
 * an array-backed key/value iterator value explicitly. Keep that runtime shape
 * consistent with the other process-local iterator overrides.
 */
class ArrayKeyValueIterator<T> {
	final array:Array<T>;
	final ref:Any;
	var current:Int = 0;

	public function new(array:Array<T>) {
		this.array = array;
		this.ref = untyped __elixir__('make_ref()');
	}

	function stateKey():Any {
		return untyped __elixir__('{__MODULE__, {0}}', this.ref);
	}

	function currentIndex():Int {
		return untyped __elixir__('Process.get({0}, {1})', stateKey(), this.current);
	}

	public function hasNext():Bool {
		return currentIndex() < array.length;
	}

	public function next():{key:Int, value:T} {
		var index = currentIndex();
		untyped __elixir__('Process.put({0}, {1} + 1)', stateKey(), index);
		return {key: index, value: array[index]};
	}
}
