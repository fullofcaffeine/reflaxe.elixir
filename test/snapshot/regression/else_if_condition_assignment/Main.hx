/**
 * Regression for haxe.elixir.codex-u8x: an assignment inside an `else if`
 * condition, such as `else if ((v = m.get(k)) > 0)`.
 *
 * Haxe runs the assignment before it tests the condition, so the later
 * branches and the code after the `if` see the new value. `expected.stdout` is
 * the output of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		var m = ["a" => -5, "b" => 4];
		Sys.println(condAssign(m, "a"));
		Sys.println(condAssign(m, "b"));
		Sys.println(condAssign(m, "x"));
		Sys.println(condAssignAfter(m, "a"));
		Sys.println(condAssignAfter(m, "b"));
		Sys.println(condAssignAfter(m, "x"));
	}

	/** The last branch reads the value assigned in the condition before it. */
	public static function condAssign(m:Map<String, Int>, k:String):Int {
		var v:Int = 0;
		if (k == "x")
			v = 100;
		else if ((v = m.get(k)) > 0)
			v = v * 2;
		else
			v = v - 1;
		return v;
	}

	/** No branch writes `v`; only the code after the `if` reads it. */
	public static function condAssignAfter(m:Map<String, Int>, k:String):String {
		var v:Int = 0;
		var label = "key ";
		if (k == "x")
			label = label + "x";
		else if ((v = m.get(k)) > 0)
			label = "positive";
		else
			label = "other";
		return label + ":" + v;
	}
}
