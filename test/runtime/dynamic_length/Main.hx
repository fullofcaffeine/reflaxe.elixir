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

	public static function main():Void {
		expect(lengthOf("Hello World"), 11);
		expect(lengthOf(""), 0);
		expect(lengthOf([1, 2, 3]), 3);
		expect(lengthOf([]), 0);
		expect(lengthOf({length: 7}), 7);
		expect(next().length, 3);
		expect(reads, 1);
	}
}
