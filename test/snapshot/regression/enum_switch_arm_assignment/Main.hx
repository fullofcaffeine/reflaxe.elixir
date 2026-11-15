/** An optional string. */
enum Opt {
	Some(v:String);
	None;
}

/**
 * Regression for haxe.elixir.codex-1mq: a statement `switch` on an enum whose
 * arm assigns an outer variable, such as `case Some(v): out = v;`.
 *
 * The arm value must reach the variable after the switch. The compiler kept the
 * old value of `out`. `expected.stdout` is the output of this program on the
 * Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		Sys.println(armAssign("x"));
		Sys.println(armAssign(""));
		Sys.println(armAssignTwo("ab"));
		Sys.println(armAssignTwo(""));
	}

	static function find(s:String):Opt
		return s == "" ? None : Some(s);

	/** One arm assigns the payload; the other arm is empty. */
	public static function armAssign(k:String):String {
		var out:String = null;
		switch find(k) {
			case Some(v):
				out = v;
			case None:
		}
		return out == null ? "null" : out;
	}

	/** Both arms assign; one assigns a value built from the payload. */
	public static function armAssignTwo(k:String):String {
		var out = "start";
		switch find(k) {
			case Some(v):
				out = v + "!";
			case None:
				out = "none";
		}
		return out;
	}
}
