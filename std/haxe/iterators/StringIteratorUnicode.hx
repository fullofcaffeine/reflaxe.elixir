package haxe.iterators;

/**
 * Bootstrap-safe Unicode string iterator for the Elixir target.
 *
 * The `.cross.hx` companion is the target surface. This `.hx` file exists so
 * macro/bootstrap compilation resolves the same module instead of caching the
 * canonical Haxe stdlib iterator before target-specific overrides are active.
 */
class StringIteratorUnicode {
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
		return StringTools.fastCodeAt(s, offset++);
	}

	static public inline function unicodeIterator(s:String) {
		return new StringIteratorUnicode(s);
	}
}
