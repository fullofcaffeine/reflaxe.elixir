/** A wire value: a number kept as its canonical text, or nothing. */
enum Wire {
	NumberValue(canonical:String);
	NullValue;
}

/**
 * Regression for haxe.elixir.codex-w34: a method call on a new object inside a
 * `switch` guard or a `?:` condition.
 *
 * The compiler stores the object in a temporary variable before the call. In
 * Elixir, the guard or condition becomes the test of a `cond` clause, and the
 * two statements must still be one expression there. `runtime.exs` checks the
 * results natively.
 */
@:keep
class Main {
	static final wholeNumber = ~/^[1-9][0-9]{0,8}$/;

	static function main():Void {}

	/** The regex is created in the guard. */
	public static function guardWithNewRegex(value:Wire):Int {
		return switch value {
			case NumberValue(canonical) if (~/^[1-9][0-9]{0,8}$/.match(canonical)): Std.parseInt(canonical);
			case _: -1;
		};
	}

	/** The regex comes from a static field, which is also not a plain local variable. */
	public static function guardWithStaticRegex(value:Wire):Int {
		return switch value {
			case NumberValue(canonical) if (wholeNumber.match(canonical)): Std.parseInt(canonical);
			case _: -1;
		};
	}

	/** The regex is created in the condition of a `?:` expression in a case body. */
	public static function conditionWithNewRegex(value:Wire):Int {
		return switch value {
			case NumberValue(canonical): ~/^[1-9][0-9]{0,8}$/.match(canonical) ? Std.parseInt(canonical) : -1;
			case _: -2;
		};
	}
}
