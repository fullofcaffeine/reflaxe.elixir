package;

class Main {
	static function main() {
		testElixirInjection();
		testMultilineArgument();
	}

	static function acceptInt(value:Int):Int {
		return value;
	}

	/** Native injection is the boundary under test; ordinary product code must stay typed. */
	static function testMultilineArgument():Void {
		// An opaque native statement sequence must remain one argument with value 30.
		var statements = acceptInt(untyped __elixir__("\nraw_left = 10\nraw_right = 20\nraw_left + raw_right\n"));
		if (statements != 30)
			throw "Expected multiline native argument to return 30";
		// Line breaks in one native call must not change its result either.
		var expression = acceptInt(untyped __elixir__("Enum.sum([\n1,\n2,\n3\n])"));
		if (expression != 6)
			throw "Expected multiline native call to return 6";
	}

	static function testElixirInjection() {
		var result = untyped __elixir__("42");
		trace("Result: " + result);
	}
}
