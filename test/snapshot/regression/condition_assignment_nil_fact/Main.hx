/**
 * Regression for haxe.elixir.codex-c0o.9, second part: an assignment inside a
 * condition, such as `if ((v = m.get(k)) != "zzz")`.
 *
 * Before the `if`, the compiler knows that `v` is null. The condition gives `v`
 * a new value, so that fact no longer holds in the branches. The compiler used
 * the fact anyway and folded `v == null` to `true`. `expected.stdout` is the
 * output of this program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		var m = ["a" => "apple", "z" => "zzz"];
		for (k in ["a", "q", "z"]) {
			Sys.println(nilThenAssigned(m, k));
			Sys.println(setThenAssigned(m, k));
			Sys.println(sameCondition(m, k));
			Sys.println(elseBranch(m, k));
			Sys.println(valueIf(m, k));
			Sys.println(innerIf(m, k));
			Sys.println(stillFolded(k));
		}
	}

	/** `v` is null before the condition assigns it; the branch tests the new value. */
	public static function nilThenAssigned(m:Map<String, String>, k:String):String {
		var v:Null<String> = null;
		if ((v = m.get(k)) != "zzz") {
			if (v == null)
				return "nil";
			return v;
		}
		return "zzz";
	}

	/** `v` is a string before the condition assigns it; the new value can be null. */
	public static function setThenAssigned(m:Map<String, String>, k:String):String {
		var v:Null<String> = "set";
		if ((v = m.get(k)) != "zzz") {
			if (v == null)
				return "nil";
			return v;
		}
		return "zzz";
	}

	/** The same condition assigns `v` and then tests it. */
	public static function sameCondition(m:Map<String, String>, k:String):String {
		var v:Null<String> = null;
		if ((v = m.get(k)) != "zzz" && v == null)
			return "nil";
		return "other";
	}

	/** The else branch tests the value that the condition assigned. */
	public static function elseBranch(m:Map<String, String>, k:String):String {
		var v:Null<String> = null;
		if ((v = m.get(k)) == "zzz")
			return "zzz";
		else {
			if (v == null)
				return "nil";
			return v;
		}
	}

	/** The `if` is a value, not a statement. */
	public static function valueIf(m:Map<String, String>, k:String):String {
		var v:Null<String> = null;
		return (v = m.get(k)) != "zzz" ? (v == null ? "nil" : v) : "zzz";
	}

	/** The assigning `if` is inside another `if`. */
	public static function innerIf(m:Map<String, String>, k:String):String {
		var v:Null<String> = null;
		if (k != "") {
			if ((v = m.get(k)) != "zzz") {
				if (v == null)
					return "nil";
				return v;
			}
		}
		return "zzz";
	}

	/**
	 * The branch assigns `mode`, but only after the test, so `mode` is still
	 * known to be set when the test runs. The compiler may fold the test away,
	 * and the snapshot keeps that output.
	 */
	public static function stillFolded(k:String):String {
		var mode:Null<String> = "asc";
		if (mode == null) {
			mode = k;
			return mode + "!";
		}
		return mode + k;
	}
}
