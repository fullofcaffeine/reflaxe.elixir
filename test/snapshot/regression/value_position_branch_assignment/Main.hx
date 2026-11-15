/** An optional string. */
enum Opt {
	Some(v:String);
	None;
}

/**
 * Regression for haxe.elixir.codex-pap: a `switch`, `if` or ternary in value
 * position whose branch assigns an outer variable, such as
 * `var r = switch o { case Some(v): out = v; 1; case None: 0; }`.
 *
 * Both the value (`r`) and the assignment (`out`) must reach the code after
 * the expression. The compiler kept the value and lost the assignment, also
 * for the state of a loop. `expected.stdout` is the output of this program on
 * the Haxe interpreter.
 */
@:keep
class Main {
	static function main():Void {
		for (k in ["x", ""]) {
			Sys.println(switchValue(find(k)));
			Sys.println(switchCallSubject(k));
			Sys.println(ifValue(k));
			Sys.println(ifAssignment(k));
			Sys.println(ternaryAssignmentBranch(k));
			Sys.println(nestedTernaryBinding(k));
			Sys.println(nestedSwitch(find(k), k == ""));
			Sys.println(shadowedLocal(k == "x"));
			Sys.println(throwingBranch(k == "x"));
			Sys.println(returnsUpdated(k));
			Sys.println(returnsValueOnly(k));
		}
		Sys.println(nestedTernaryBinding("y"));
		Sys.println(nestedSwitch(Some("q"), true));
		Sys.println(allowed(["a", "order", "b"]));
		Sys.println(allowed(["a", "b"]));
		Sys.println(allowed([]));
		Sys.println(lastSome([Some("a"), None, Some("bcd")]));
		Sys.println(largest([1, 5, 2, 9, 3]));
		Sys.println(oddSteps(5));
		Shadowing.run();
	}

	public static function find(s:String):Opt
		return s == "" ? None : Some(s);

	static function score(k:String):Int
		return k == "x" ? 7 : (k == "y" ? -7 : 0);

	/** A value `switch`; one arm assigns the payload to an outer variable. */
	public static function switchValue(o:Opt):String {
		var out = "d";
		var r = switch o {
			case Some(v):
				out = v;
				1;
			case None: 0;
		};
		return out + r;
	}

	/** The subject is a call, so the compiler first stores it in a temporary. */
	public static function switchCallSubject(k:String):String {
		var out = "d";
		var r = switch find(k) {
			case Some(v):
				out = v;
				v.length;
			case None: 0;
		};
		return out + r;
	}

	/** A value `if`; only one branch assigns. */
	public static function ifValue(k:String):String {
		var v = 1;
		var r = if (k == "x") {
			v = 2;
			"a";
		} else "b";
		return r + v;
	}

	/** The value goes to an existing variable, and the branches read it. */
	public static function ifAssignment(k:String):String {
		var v = 1;
		var r = "r";
		r = if (k == "x") {
			v = v + 1;
			r + "a";
		} else {
			v = v + 2;
			r + "b";
		};
		return r + v;
	}

	/** The branch value is itself the assignment. */
	public static function ternaryAssignmentBranch(k:String):String {
		var v = 1;
		var r = k == "x" ? (v = 2) : 0;
		return r + "/" + v;
	}

	/** The condition of the inner ternary assigns. */
	public static function nestedTernaryBinding(k:String):String {
		var v = 1;
		var r = k == "" ? "empty" : ((v = score(k)) > 0 ? "pos" : "other");
		return r + v;
	}

	/** Value `if` and `switch` inside an arm of a value `switch`; two variables change. */
	public static function nestedSwitch(o:Opt, flag:Bool):String {
		var out = "d";
		var hits = 0;
		var r = switch o {
			case Some(v):
				out = v;
				var inner = if (flag) {
					hits = hits + 10;
					"f";
				} else "n";
				var size = switch find(v + v) {
					case Some(w):
						hits++;
						w.length;
					case None: 0;
				};
				inner + size;
			case None:
				if (flag) {
					hits = -1;
					"none!";
				} else "none";
		};
		return r + "/" + out + "/" + hits;
	}

	/** A `var` inside the branch has the name of an outer variable; the outer one keeps its value. */
	public static function shadowedLocal(c:Bool):String {
		var v = 1;
		var seen = 0;
		var r = if (c) {
			var v = score("x");
			seen = v;
			v + 1;
		} else 0;
		return r + "/" + v + "/" + seen;
	}

	/** One branch assigns and has a value; the other one throws and has none. */
	public static function throwingBranch(c:Bool):String {
		var out = "d";
		try {
			var r = if (c) {
				out = "set";
				1;
			} else throw "boom";
			return out + r;
		} catch (e:String) {
			return out + e;
		}
	}

	/** The function ends by returning the variable that an arm assigned, not the value. */
	public static function returnsUpdated(k:String):String {
		var out = "d";
		var hit = switch find(k) {
			case Some(v):
				out = v;
				true;
			case None: false;
		};
		if (hit)
			out = out + "!";
		return out;
	}

	/** The function ends by returning the value; nothing reads `out` after the `switch`. */
	public static function returnsValueOnly(k:String):Int {
		var out = "d";
		return switch find(k) {
			case Some(v):
				out = v + out;
				out.length;
			case None: 0;
		};
	}

	/**
	 * The loop shape that failed in an application: the value `switch` sets a
	 * flag, and the loop can return early. The function always returned false.
	 */
	public static function allowed(names:Array<String>):Bool {
		var seen = false;
		for (name in names) {
			final ok = switch name {
				case "order":
					seen = true;
					name.length > 0;
				case _: true;
			};
			if (!ok)
				return false;
		}
		return seen;
	}

	/** A value `switch` in a loop without an early return. */
	public static function lastSome(items:Array<Opt>):String {
		var last = "none";
		var total = 0;
		for (item in items) {
			var n = switch item {
				case Some(v):
					last = v;
					v.length;
				case None: 0;
			};
			total += n;
		}
		return last + "/" + total;
	}

	/** A value `if` in a loop. */
	public static function largest(xs:Array<Int>):String {
		var big = 0;
		var labels = "";
		for (x in xs) {
			var label = if (x > big) {
				big = x;
				"B";
			} else "s";
			labels += label;
		}
		return labels + big;
	}

	/** A ternary with an assignment branch in a `while` loop. */
	public static function oddSteps(n:Int):String {
		var i = 0;
		var odd = 0;
		var acc = "";
		while (i < n) {
			var t = i % 2 == 1 ? (odd = i) : 0;
			acc += t;
			i++;
		}
		return acc + "/" + odd;
	}
}
