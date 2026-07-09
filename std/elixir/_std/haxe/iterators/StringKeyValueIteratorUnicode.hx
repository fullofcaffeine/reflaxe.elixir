package haxe.iterators;

/**
 * Elixir-target Unicode key/value string iterator.
 *
 * Keys are character indices, not byte offsets. This matches Elixir's
 * codepoint-indexed String lowering and avoids UTF-16 surrogate-pair skipping.
 */
class StringKeyValueIteratorUnicode {
	var offset = 0;
	var s:String;

	public inline function new(s:String) {
		this.s = s;
	}

	public inline function hasNext() {
		return s.charAt(offset) != "";
	}

	@:access(StringTools)
	public inline function next() {
		return {key: offset, value: StringTools.fastCodeAt(s, offset++)};
	}

	static public inline function unicodeKeyValueIterator(s:String) {
		return new StringKeyValueIteratorUnicode(s);
	}
}
