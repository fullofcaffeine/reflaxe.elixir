package haxe.iterators;

/**
 * Bootstrap-safe Unicode key/value string iterator for the Elixir target.
 *
 * The `.cross.hx` companion is the target surface. This `.hx` file exists so
 * macro/bootstrap compilation resolves the same module instead of caching the
 * canonical Haxe stdlib iterator before target-specific overrides are active.
 */
class StringKeyValueIteratorUnicode {
	var offset = 0;
	var s:String;

	public inline function new(s:String) {
		this.s = s;
	}

	public inline function hasNext() {
		return offset < s.length;
	}

	@:access(StringTools)
	public inline function next() {
		return {key: offset, value: StringTools.fastCodeAt(s, offset++)};
	}

	static public inline function unicodeKeyValueIterator(s:String) {
		return new StringKeyValueIteratorUnicode(s);
	}
}
