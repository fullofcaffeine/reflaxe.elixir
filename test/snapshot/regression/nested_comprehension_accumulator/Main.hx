/** A result whose `Error` payload the comprehensions read. */
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

/**
 * Regression for haxe.elixir.codex-uplw: an array comprehension with two or
 * more `for` clauses, such as `[for (x in xs) for (y in ys) x + y]`.
 *
 * Every element that the inner loop adds must reach the result. The compiler
 * returned `[]`: the inner loop started again from the empty list, and the
 * outer loop dropped its result. `expected.stdout` is the output of this
 * program on the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		Sys.println("twoPlain " + twoPlain(["a", "b"], ["1", "2"]));
		Sys.println("statementLoops " + statementLoops(["a", "b"], ["1", "2"]));
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("twoSwitch " + twoSwitch(r, ["a", "b"], ["1", "2"]));
			Sys.println("twoSwitchGuard " + twoSwitchGuard(r, ["a", "b"], ["1", "2"]));
			Sys.println("threeSwitch " + threeSwitch(r, ["a", "b"], ["1", "2"], ["p", "q"]));
			Sys.println("twoFilter " + twoFilter(r, [1, 2, 3], [1, 2, 3]));
			Sys.println("innerRange " + innerRange(r, ["a", "b"], 3));
			Sys.println("innerMap " + innerMap(r, ["a", "b"], ["k" => 1, "j" => 2]));
			Sys.println("named " + named(r, ["a", "b"], ["1", "2", "3"]));
		}
		Sys.println("emptyInner " + twoPlain(["a", "b"], []));
		Sys.println("emptyOuter " + twoPlain([], ["1", "2"]));
	}

	/** Two `for` clauses, no `switch`: the smallest failing shape. */
	public static function twoPlain(xs:Array<String>, ys:Array<String>):String {
		return [for (x in xs) for (y in ys) x + y].join(",");
	}

	/** The same nesting written as statements that add to an outer array. */
	public static function statementLoops(xs:Array<String>, ys:Array<String>):String {
		final out = [];
		for (x in xs)
			for (y in ys)
				out.push(y + x);
		return out.join(",");
	}

	/** Two `for` clauses around a `switch`; the `Error` arm reads both loop variables. */
	public static function twoSwitch(r:Verdict, xs:Array<String>, ys:Array<String>):String {
		return [
			for (x in xs)
				for (y in ys)
					switch (r) {
						case Error(e):
							x + y + e;
						case Ok(_):
							"o";
					}
		].join(",");
	}

	/** A guarded `Error` arm that tests the outer loop variable. */
	public static function twoSwitchGuard(r:Verdict, xs:Array<String>, ys:Array<String>):String {
		return [
			for (x in xs)
				for (y in ys)
					switch (r) {
						case Error(e) if (x == "a"):
							x + y + e;
						case Error(_):
							"E" + y;
						case Ok(_):
							"o";
					}
		].join(",");
	}

	/** Three `for` clauses. */
	public static function threeSwitch(r:Verdict, xs:Array<String>, ys:Array<String>, zs:Array<String>):String {
		return [
			for (x in xs)
				for (y in ys)
					for (z in zs)
						switch (r) {
							case Error(e):
								x + y + z + e;
							case Ok(_):
								"o";
						}
		].join(",");
	}

	/** An `if` filter on each loop. */
	public static function twoFilter(r:Verdict, xs:Array<Int>, ys:Array<Int>):String {
		return [
			for (x in xs)
				if (x > 1) for (y in ys)
					if (y != x)
						switch (r) {
							case Error(e):
								x + "" + y + e;
							case Ok(_):
								"o";
						}
		].join(",");
	}

	/** The inner loop runs over an integer range whose end is not a constant. */
	public static function innerRange(r:Verdict, xs:Array<String>, n:Int):String {
		return [
			for (x in xs)
				for (i in 1...n)
					switch (r) {
						case Error(e):
							x + i + e;
						case Ok(_):
							"o";
					}
		].join(",");
	}

	/** The inner loop runs over the keys of a map; the result is sorted because map order differs by target. */
	public static function innerMap(r:Verdict, xs:Array<String>, m:Map<String, Int>):String {
		final out = [
			for (x in xs)
				for (k in m.keys())
					switch (r) {
						case Error(e):
							x + k + e;
						case Ok(_):
							"o";
					}
		];
		out.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return out.join(",");
	}

	/** The comprehension is stored in a local before it is read. */
	public static function named(r:Verdict, xs:Array<String>, ys:Array<String>):Int {
		final items = [
			for (x in xs)
				for (y in ys)
					switch (r) {
						case Error(e):
							x + y + e;
						case Ok(_):
							"o";
					}
		];
		return items.length;
	}
}
