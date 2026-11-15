/**
 * Regression for haxe.elixir.codex-u8x, second part: an assignment on the right
 * side of `&&` or `||` in the test of an `if` statement.
 *
 * Haxe keeps the assignment for the branches and for the code after the `if`.
 * Elixir runs the right side of `and` and `or` in a scope of its own, so the
 * compiler must not leave the assignment there. `expected.stdout` is the output
 * of this program on the Haxe interpreter.
 *
 * Each function reads the first value of `r` in one branch. A first value that
 * no branch reads gives an unused-variable warning that is not part of this
 * bug (haxe.elixir.codex-zb6).
 */
@:keep
class Main {
	static function main():Void {
		var m = ["a" => -5, "b" => 4, "c" => 40];
		for (k in ["a", "b", "c", "x", "z"]) {
			Sys.println(andTest(m, k));
			Sys.println(orTest(m, k));
			Sys.println(middleOfChain(m, k));
			Sys.println(negatedTest(m, k));
			Sys.println(withoutElse(m, k));
			Sys.println(branchReads(m, k));
		}
	}

	static function get(m:Map<String, Int>, k:String):Int {
		var found = m.get(k);
		return found == null ? 0 : found;
	}

	/** The right side of `&&` assigns `v`; the code after the `if` reads it. */
	public static function andTest(m:Map<String, Int>, k:String):String {
		var v = 1;
		var r = "key ";
		if (k == "x")
			r = r + "x";
		else if (k != "z" && (v = get(m, k)) > 0)
			r = "pos";
		else
			r = "other";
		return r + v;
	}

	/** The right side of `||` assigns `v`. */
	public static function orTest(m:Map<String, Int>, k:String):String {
		var v = 1;
		var r = "key ";
		if (k == "x")
			r = r + "x";
		else if (k == "z" || (v = get(m, k)) > 0)
			r = "zpos";
		else
			r = "other";
		return r + v;
	}

	/** The assignment is in the middle of a chain; the last test reads it. */
	public static function middleOfChain(m:Map<String, Int>, k:String):String {
		var v = 1;
		var r = "size ";
		if (k != "z" && (v = get(m, k)) > 0 && v < 10)
			r = r + "small";
		else
			r = "other";
		return r + v;
	}

	/** The test is negated, so the branches change places. */
	public static function negatedTest(m:Map<String, Int>, k:String):String {
		var v = 1;
		var r = "positive ";
		if (!(k != "z" && (v = get(m, k)) > 0))
			r = r + "no";
		else
			r = "yes";
		return r + v;
	}

	/** An `if` without `else`. */
	public static function withoutElse(m:Map<String, Int>, k:String):String {
		var v = 1;
		var r = "none";
		if (k != "z" && (v = get(m, k)) > 0)
			r = "pos";
		return r + v;
	}

	/** Both branches read the assigned value. */
	public static function branchReads(m:Map<String, Int>, k:String):String {
		var v = 1;
		if (k != "z" && (v = get(m, k)) > 0)
			return "pos" + v;
		else
			return "other" + v;
	}
}
