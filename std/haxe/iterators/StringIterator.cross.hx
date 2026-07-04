package haxe.iterators;

/**
 * Elixir target runtime for `haxe.iterators.StringIterator`.
 *
 * Elixir strings are immutable binaries, so the stateful Haxe iterator offset
 * is stored in the process dictionary under an iterator-local reference.
 */
class StringIterator {
	final s:String;
	final ref:Any;
	var offset:Int = 0;

	public function new(s:String) {
		this.s = s;
		this.ref = untyped __elixir__('make_ref()');
	}

	function stateKey():Any {
		return untyped __elixir__('{__MODULE__, {0}}', this.ref);
	}

	function currentOffset():Int {
		return untyped __elixir__('Process.get({0}, {1})', stateKey(), this.offset);
	}

	public function hasNext():Bool {
		return untyped __elixir__('String.at({0}, {1}) != nil', this.s, currentOffset());
	}

	@:access(StringTools)
	public function next():Int {
		var index = currentOffset();
		untyped __elixir__('Process.put({0}, {1} + 1)', stateKey(), index);
		return untyped __elixir__('Enum.at(String.to_charlist({0}), {1})', this.s, index);
	}
}
