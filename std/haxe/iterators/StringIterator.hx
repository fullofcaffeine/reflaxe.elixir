package haxe.iterators;

/**
 * Bootstrap-safe plain string iterator for the Elixir target.
 *
 * The `.cross.hx` companion owns runtime state. This `.hx` file keeps
 * macro/bootstrap compilation from caching the canonical stdlib iterator before
 * the Elixir target std roots are active.
 */
class StringIterator {
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
}
