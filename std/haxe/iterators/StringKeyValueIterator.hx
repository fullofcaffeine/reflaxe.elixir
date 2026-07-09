package haxe.iterators;

/**
 * Bootstrap-safe plain string key/value iterator for the Elixir target.
 *
 * The `.cross.hx` companion owns runtime state. This `.hx` file keeps
 * macro/bootstrap compilation from caching the canonical stdlib iterator before
 * the Elixir target std roots are active.
 */
@:ifFeature("haxe.iterators.StringKeyValueIterator.*", "StringTools.keyValueIterator")
class StringKeyValueIterator {
	var offset = 0;
	var s:String;

	public inline function new(s:String) {
		this.s = s;
	}

	public inline function hasNext() {
		return offset < s.length;
	}

	@:access(StringTools)
	public inline function next():{key:Int, value:Int} {
		return {key: offset, value: StringTools.fastCodeAt(s, offset++)};
	}
}
