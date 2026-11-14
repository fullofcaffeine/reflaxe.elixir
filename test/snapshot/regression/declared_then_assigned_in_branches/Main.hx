/**
 * Regression for haxe.elixir.codex-cwp: two variables that are declared without
 * a value and then assigned in every branch of an `if`.
 *
 * The generated Elixir must compile without "variable is unused" warnings, and
 * the values must be right. `runtime.exs` checks the values natively; the
 * runtime smoke compile refuses warnings.
 */
@:keep
class Main {
	static function main():Void {}

	/** Splits `digits` at `position` into a whole part and a fraction part. */
	public static function split(digits:String, position:Int):String {
		var whole:String;
		var fraction:String;
		if (position <= 0) {
			whole = "0";
			fraction = digits;
		} else if (position >= digits.length) {
			whole = digits;
			fraction = "";
		} else {
			whole = digits.substr(0, position);
			fraction = digits.substr(position);
		}
		if (whole == "")
			whole = "0";
		return fraction == "" ? whole : whole + "." + fraction;
	}

	/** One branch leaves the declared value unset, so its null must stay readable. */
	public static function label(count:Int):String {
		var text:Null<String> = null;
		if (count > 0)
			text = "some";
		return text == null ? "none" : text;
	}
}
