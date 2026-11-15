/** A result whose payload names are also common names of local variables. */
enum Res {
	Ok(value:Int);
	Error(reason:String);
}

/**
 * Shapes where one branch assigns an outer variable and another branch has a
 * different variable with the same name: a pattern binder, or a `var` of its
 * own.
 *
 * Haxe keeps the two apart. In Elixir both have one name, and a hoisted
 * branch returns the updated variables at its end. The branch with the other
 * variable must return the OUTER value there, not its own. Each function
 * prints `result/outer variable(s)`.
 */
@:keep
class Shadowing {
	public static function run():Void {
		for (r in [Ok(3), Error("bad")]) {
			Sys.println(binderValue(r));
			Sys.println(binderStatement(r));
			Sys.println(binderTwoUpdates(r));
			Sys.println(localInArm(r));
			Sys.println(captureNameTaken(r));
		}
		for (o in [Main.find("payload"), Main.find("")]) {
			Sys.println(binderOpt(o));
			Sys.println(binderOtherWrite(o));
			Sys.println(pushValue(o));
			Sys.println(pushStatement(o));
			Sys.println(armLocalInsideIf(o, true));
			Sys.println(armLocalInsideIf(o, false));
		}
		for (c in [true, false]) {
			Sys.println(localValue(c));
			Sys.println(localStatement(c));
			Sys.println(writeThenLocal(c));
			Sys.println(loopValue(c, [1, 2, 3]));
			Sys.println(loopStatement(c, [1, 2, 3]));
			Sys.println(rangeLoopLocal(c));
			Sys.println(arrayLoopLocal(c));
		}
	}

	/**
	 * The program has variables with the names that the compiler would give
	 * its first captures. The compiler must pick other names. This function
	 * comes first so that the numbering starts here.
	 */
	public static function captureNameTaken(r:Res):String {
		var reflaxe_outer_value_1 = 7;
		var reflaxe_outer_value_2 = 8;
		var value = 100;
		var ok = switch r {
			case Ok(value): value > 0;
			case Error(_):
				value = value + 1;
				false;
		};
		return ok + "/" + value + "/" + reflaxe_outer_value_1 + "/" + reflaxe_outer_value_2;
	}

	static function id(n:Int):Int
		return n;

	static function fresh():Array<String>
		return ["local", "z"];

	/** The `Ok` pattern binds `value`; the `Error` arm assigns the outer `value`. */
	public static function binderValue(r:Res):String {
		var value = 100;
		var ok = switch r {
			case Ok(value): value > 0;
			case Error(_):
				value = value + 1;
				false;
		};
		return ok + "/" + value;
	}

	/** The same in statement position. */
	public static function binderStatement(r:Res):String {
		var value = 100;
		var ok = false;
		switch r {
			case Ok(value):
				ok = value > 0;
			case Error(_):
				value = value + 1;
		}
		return ok + "/" + value;
	}

	/** Two outer variables change; the pattern binds the name of one of them. */
	public static function binderTwoUpdates(r:Res):String {
		var value = 100;
		var reason = "outer";
		var code = switch r {
			case Ok(value): value + 1;
			case Error(e):
				reason = e;
				value = 0;
				-1;
		};
		return code + "/" + value + "/" + reason;
	}

	/** The `Ok` arm declares its own `count`; the `Error` arm assigns the outer one. */
	public static function localInArm(r:Res):String {
		var count = 10;
		var label = switch r {
			case Ok(v):
				var count = id(v) * 2;
				"ok" + count;
			case Error(e):
				count = count + e.length;
				"err";
		};
		return label + "/" + count;
	}

	/** An `Opt` pattern binds `out`; the other arm assigns the outer `out`. */
	public static function binderOpt(o:Main.Opt):String {
		var out = "d";
		var r = switch o {
			case Some(out): out.length;
			case None:
				out = "none";
				0;
		};
		return r + "/" + out;
	}

	/** The arm that binds `v` also assigns another outer variable. */
	public static function binderOtherWrite(o:Main.Opt):String {
		var v = "outer";
		var n = 1;
		var r = switch o {
			case Some(v):
				n = n + v.length;
				v + "!";
			case None:
				n = -n;
				v = "none";
				v;
		};
		return r + "/" + v + "/" + n;
	}

	/**
	 * `items.push(v)` rebinds `items` in Elixir. The other arm declares its
	 * own `items`; that must not hide the push.
	 */
	public static function pushValue(o:Main.Opt):String {
		var items = ["a"];
		var r = switch o {
			case Some(v):
				items.push(v);
				1;
			case None:
				var items = fresh();
				items.length + 10;
		};
		return r + "/" + items.join(",");
	}

	/** The same in statement position. */
	public static function pushStatement(o:Main.Opt):String {
		var items = ["a"];
		var r = 1;
		switch o {
			case Some(v):
				items.push(v);
				r = r + 1;
			case None:
				var items = fresh();
				r = r + items.length + 10;
		}
		return r + "/" + items.join(",");
	}

	/** One branch declares its own `v`; the other branch assigns the outer `v`. */
	public static function localValue(c:Bool):String {
		var v = 1;
		var r = if (c) {
			var v = id(5);
			v + 1;
		} else {
			v = v + 1;
			0;
		};
		return r + "/" + v;
	}

	/** The same in statement position. */
	public static function localStatement(c:Bool):String {
		var v = 1;
		var r = 0;
		if (c) {
			var v = id(5);
			r = v + 1;
		} else {
			v = v + 1;
		}
		return r + "/" + v;
	}

	/** One branch first assigns the outer `v` and then declares its own `v`. */
	public static function writeThenLocal(c:Bool):String {
		var v = 1;
		var r = if (c) {
			v = v + 1;
			var v = id(5);
			v + 1;
		} else 0;
		return r + "/" + v;
	}

	/** A loop changes the outer `sum` in one branch; the other branch declares its own `sum`. */
	public static function loopValue(c:Bool, xs:Array<Int>):String {
		var sum = 100;
		var r = if (c) {
			for (x in xs)
				sum += x;
			"loop";
		} else {
			var sum = id(7);
			"local" + sum;
		};
		return r + "/" + sum;
	}

	/**
	 * The body of a loop over a constant range declares its own `v`. The
	 * compiler unrolls such a loop into plain blocks, one for each step.
	 */
	public static function rangeLoopLocal(c:Bool):String {
		var v = 1;
		var total = 0;
		var r = if (c) {
			for (x in 0...3) {
				var v = id(x) * 2;
				total += v;
			}
			total;
		} else {
			v = v + 1;
			0;
		};
		return r + "/" + v;
	}

	/** The same with a loop over a constant array. */
	public static function arrayLoopLocal(c:Bool):String {
		var v = 1;
		var total = 0;
		var r = if (c) {
			for (x in [1, 2, 3]) {
				var v = id(x) * 2;
				total += v;
			}
			total;
		} else {
			v = v + 1;
			0;
		};
		return r + "/" + v;
	}

	/**
	 * A statement `switch` inside a value `if`. One arm has a binder and
	 * declares its own `n`; the other arm assigns the outer `n`. The body of
	 * the first arm is a plain block behind the binder.
	 */
	public static function armLocalInsideIf(o:Main.Opt, c:Bool):String {
		var n = 0;
		var seen = 0;
		var out = if (c) {
			switch o {
				case Some(x):
					var n = x.length;
					seen = n;
				case None:
					n = -1;
			}
			seen;
		} else 0;
		return out + "/" + n;
	}

	/** The same in statement position. */
	public static function loopStatement(c:Bool, xs:Array<Int>):String {
		var sum = 100;
		var r = "r";
		if (c) {
			for (x in xs)
				sum += x;
			r = r + "loop";
		} else {
			var sum = id(7);
			r = r + "local" + sum;
		}
		return r + "/" + sum;
	}
}
