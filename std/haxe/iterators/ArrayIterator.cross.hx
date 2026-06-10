package haxe.iterators;

/**
 * Elixir target runtime for `haxe.iterators.ArrayIterator`.
 *
 * Preserves Haxe's stateful iterator API by storing the current index in the
 * process dictionary keyed by an iterator-local `ref`.
 */
@:coreApi
class ArrayIterator<T> {
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
		return untyped __elixir__('{0} < length({1})', currentIndex(), this.array);
	}

	public function next():T {
		return untyped __elixir__('index = {0}
    Process.put({1}, index + 1)
    Enum.at({2}, index)', currentIndex(), stateKey(), this.array);
	}
}
