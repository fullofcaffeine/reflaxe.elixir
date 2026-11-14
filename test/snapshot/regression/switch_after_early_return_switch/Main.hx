/** The result of a step: a value, or the reason why the step failed. */
enum Outcome<T, E> {
	Ok(value:T);
	Err(error:E);
}

/**
 * Regression for haxe.elixir.codex-vh7: a switch that follows an early-return switch.
 *
 * Haxe stores the value of each switch in a temporary variable with the same
 * name. The second switch must test its own value, and the first call must
 * run once. `runtime.exs` checks both natively.
 */
@:keep
class Main {
	static function main():Void {}

	/** Reports each lookup to the caller, then returns the key or an error for an empty key. */
	static function lookup(key:String, observe:String->Void):Outcome<String, String> {
		observe(key);
		return key == "" ? Err("empty") : Ok(key);
	}

	/** Returns null for the word "none" and the word itself otherwise. */
	static function wordOf(text:String):Null<String>
		return text == "none" ? null : text;

	/** Looks the key up, then maps the found word to a depth. */
	public static function depthOf(key:String, observe:String->Void):Outcome<Int, String> {
		final found = switch lookup(key, observe) {
			case Ok(value): value;
			case Err(error): return Err(error);
		};
		final depth = switch wordOf(found) {
			case "summary": 1;
			case "body": 2;
			case _: return Err("unknown depth");
		};
		return Ok(depth);
	}
}
