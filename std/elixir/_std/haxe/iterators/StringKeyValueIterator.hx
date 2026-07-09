package haxe.iterators;

/**
 * Elixir target runtime for `haxe.iterators.StringKeyValueIterator`.
 *
 * Keys are character indices and values are codepoints, matching this target's
 * codepoint-indexed `String.length` and `StringTools.fastCodeAt` lowering.
 */
@:ifFeature("haxe.iterators.StringKeyValueIterator.*", "StringTools.keyValueIterator")
class StringKeyValueIterator {
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
	public function next():{key:Int, value:Int} {
		var index = currentOffset();
		untyped __elixir__('Process.put({0}, {1} + 1)', stateKey(), index);
		return {key: index, value: untyped __elixir__('Enum.at(String.to_charlist({0}), {1})', this.s, index)};
	}
}
