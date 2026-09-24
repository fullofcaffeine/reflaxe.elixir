/** Exercises Haxe's dynamic field boundary, not a statically known String/Array shortcut. */
class Main {
	static var reads:Int = 0;

	public static function lengthOf(value:Dynamic):Int {
		return value.length;
	}

	static function next():Dynamic {
		reads = reads + 1;
		return "abc";
	}

	static function expect(actual:Int, expected:Int):Void {
		if (actual != expected)
			throw "Dynamic length contract failed";
	}

	/** Dynamic array reads must use array indexing, not the native map protocol. */
	public static function readAt(value:Dynamic, index:Int):Null<Int> {
		return value[index];
	}

	#if reflaxe_runtime
	/** Native maps cross this Dynamic boundary; their keys are not array indices. */
	static function readNativeAt(value:Dynamic, key:Dynamic):Null<Int> {
		return value[key];
	}
	#end

	/** Keep the runtime type argument rather than folding a concrete value test. */
	public static function matchesDynamic(value:Dynamic):Bool {
		return Std.isOfType(value, Dynamic);
	}

	static function nextArray():Dynamic {
		reads = reads * 10 + 1;
		return [11, 22];
	}

	static function nextIndex():Int {
		reads = reads * 10 + 2;
		return 1;
	}

	public static function main():Void {
		expect(lengthOf("Hello World"), 11);
		expect(lengthOf(""), 0);
		expect(lengthOf([1, 2, 3]), 3);
		expect(lengthOf([]), 0);
		expect(lengthOf({length: 7}), 7);
		expect(next().length, 3);
		expect(reads, 1);
		if (readAt([11, 22], 0) != 11 || readAt([11, 22], 1) != 22)
			throw "Dynamic numeric indexing must read array elements";
		if (readAt([], 0) != null || readAt([11], 1) != null || readAt([11], -1) != null)
			throw "Out-of-range array reads must return null";
		if (readAt(nextArray(), nextIndex()) != 22)
			throw "Dynamic indexing must preserve the supplied operands";
		expect(reads, 112);
		if (nextArray()[nextIndex()] != 22)
			throw "Direct Dynamic indexing must preserve the supplied operands";
		expect(reads, 11212);
		var values:Dynamic = [11, 22];
		var index = 0;
		var selected = values[
			{
				values = [99];
				index = index + 1;
				index;
			}
		];
		if (selected != 22 || index != 1 || readAt(values, 0) != 99)
			throw "Dynamic indexing must capture the original receiver and retain caller writes";
		#if reflaxe_runtime
		// This target representation is not a Haxe Map. Use its typed extern to
		// construct it, then exercise ordinary indexing through the Dynamic edge.
		var nativeMap = elixir.ElixirMap.putTerm(elixir.ElixirMap.new_(), "name", 7);
		nativeMap = elixir.ElixirMap.putTerm(nativeMap, 0, 42);
		if (readNativeAt(nativeMap, "name") != 7 || readNativeAt(nativeMap, 0) != 42 || readNativeAt(nativeMap, "missing") != null)
			throw "Dynamic native map access must preserve keys and missing entries";
		#end
		if (matchesDynamic(null) || !matchesDynamic(0) || !matchesDynamic(false) || !matchesDynamic("text") || !matchesDynamic([])
			|| !matchesDynamic({name: "test"}))
			throw "Dynamic runtime type checks must match every non-null value";
	}
}
