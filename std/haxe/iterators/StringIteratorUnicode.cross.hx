package haxe.iterators;

/**
 * Elixir-target Unicode string iterator.
 *
 * Elixir strings are UTF-8 binaries and `String.length/1` / charlist access are
 * already codepoint-indexed in our lowering, so this must use the non-UTF16
 * Haxe iterator semantics even if the compiler carries a generic `utf16` define.
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
