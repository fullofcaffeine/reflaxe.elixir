/** A result whose two payloads have the generic name `v`. */
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

/**
 * Regression for haxe.elixir.codex-mj83: a visible variable named `value` or
 * `reason` that an `Ok(v)` or `Error(v)` clause does not read itself.
 *
 * The compiler can move code into a clause after it has named the clause's
 * binder. When one arm returns early, the statements after the switch run
 * inside the other arm. That code reads the outer variable, so the binder must
 * not have its name. Later passes that repair a clause by name must also leave
 * a name alone when a closure, loop or `catch` around the clause binds it.
 */
class VisibleNames {
	/** Runs every shape for an `Ok` and an `Error` value and prints the results. */
	public static function run():Void {
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("argument " + argument(r, "P"));
			Sys.println("local " + local(r));
			Sys.println("reasonArgument " + reasonArgument(r, "why"));
			Sys.println("twoSwitches " + twoSwitches(r, Ok("q"), "P"));
			Sys.println("nested " + nested(r, Error("z"), "P", "W"));
			Sys.println("guarded " + guarded(r, "P"));
			Sys.println("inLoop " + inLoop([r, Ok("m")], "P"));
			Sys.println("closureArgument " + closureArgument(r));
			Sys.println("loopVariable " + loopVariable(r, ["a", "b"]));
			Sys.println("catchVariable " + catchVariable(r));
			Sys.println("outerBlock " + outerBlock(r, true));
			Sys.println("closureValueUnread " + closureValueUnread(r));
			Sys.println("closureReasonUnread " + closureReasonUnread(r));
			Sys.println("loopReason " + loopReason(r, ["ab", "cde"]));
			Sys.println("pushed " + pushed(r));
			Sys.println("indexSet " + indexSet(r));
			Sys.println("mapSet " + mapSet(r));
			Sys.println("fieldSet " + fieldSet(r));
		}
	}

	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	/** The code after the switch reads the argument `value`. */
	public static function argument(r:Verdict, value:String):String {
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		return "r=" + value;
	}

	/** The code after the switch reads the local `value`. */
	public static function local(r:Verdict):String {
		var value = "d";
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		return "r=" + value;
	}

	/** The `Ok` arm returns; the code after the switch reads the argument `reason`. */
	public static function reasonArgument(r:Verdict, reason:String):String {
		switch (r) {
			case Ok(v):
				return "ok " + v;
			case Error(e):
				note(e);
		}
		return "r=" + reason;
	}

	/** Two switches in a row; the last statement moves into both `Ok` arms. */
	public static function twoSwitches(r:Verdict, s:Verdict, value:String):String {
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		switch (s) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err2 " + e;
		}
		return "r=" + value;
	}

	/** The code after an inner and an outer switch moves into the inner `Error` arm. */
	public static function nested(r:Verdict, s:Verdict, value:String, reason:String):String {
		switch (r) {
			case Ok(v):
				switch (s) {
					case Ok(w):
						return "inner " + w;
					case Error(e):
						note(e + v);
				}
				note(value);
			case Error(e):
				return "err " + e;
		}
		return "r=" + value + reason;
	}

	/** A guarded arm falls through; the other arms return. */
	public static function guarded(r:Verdict, value:String):String {
		switch (r) {
			case Ok(v) if (v == "o"):
				note(v);
			case Ok(v):
				return "other " + v;
			case Error(e):
				return "err " + e;
		}
		return "r=" + value;
	}

	/** The rest of a loop body moves into the arm. */
	public static function inLoop(rs:Array<Verdict>, value:String):String {
		var acc = "";
		for (r in rs) {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					return "err " + e;
			}
			acc += value;
		}
		return "r=" + acc;
	}

	/** The visible `value` is the argument of a closure. */
	public static function closureArgument(r:Verdict):String {
		var describe = function(value:String):String {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					return "err " + e;
			}
			return "r=" + value;
		};
		return describe("C");
	}

	/** The visible `value` is the variable of a `for` loop. */
	public static function loopVariable(r:Verdict, items:Array<String>):String {
		for (value in items) {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					return "err " + e;
			}
			return "r=" + value;
		}
		return "empty";
	}

	/** The visible `reason` is the variable of a `catch`. */
	public static function catchVariable(r:Verdict):String {
		try {
			throw "boom";
		} catch (reason:String) {
			switch (r) {
				case Ok(v):
					return "ok " + v;
				case Error(e):
					note(e);
			}
			return "caught " + reason;
		}
	}

	/** The visible `value` belongs to an outer block; the switch is in an inner one. */
	public static function outerBlock(r:Verdict, deep:Bool):String {
		var value = "d";
		if (deep) {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					return "err " + e;
			}
			return "deep " + value;
		}
		return "r=" + value;
	}

	/** The `Ok(v)` arm does not read its payload; it reads the closure argument `value`. */
	public static function closureValueUnread(r:Verdict):String {
		var describe = function(value:String):String {
			return switch (r) {
				case Ok(v): "ok /" + value;
				case Error(e): "err " + e;
			};
		};
		return describe("C");
	}

	/** The `Error(e)` arm does not read its payload; it reads the closure argument `reason`. */
	public static function closureReasonUnread(r:Verdict):Int {
		var measure = function(reason:String):Int {
			return switch (r) {
				case Ok(v): v.length;
				case Error(e): reason.length * 10;
			};
		};
		return measure("why");
	}

	/** The `Error(e)` arm does not read its payload; it reads the loop variable `reason`. */
	public static function loopReason(r:Verdict, reasons:Array<String>):Int {
		var total = 0;
		for (reason in reasons) {
			total += switch (r) {
				case Ok(v): v.length;
				case Error(e): reason.length * 10;
			};
		}
		return total;
	}

	/** Another arm changes `value` with a method call, not with `=`. */
	public static function pushed(r:Verdict):String {
		var value:Array<String> = ["d"];
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				value.push(e);
		}
		return "r=" + value.join(",");
	}

	/** Another arm writes an element of `value`. */
	public static function indexSet(r:Verdict):String {
		var value:Array<String> = ["d"];
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				value[0] = e;
		}
		return "r=" + value[0];
	}

	/** Another arm writes a key of the map `value`. */
	public static function mapSet(r:Verdict):String {
		var value = new Map<String, String>();
		value.set("k", "d");
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				value.set("k", e);
		}
		return "r=" + value.get("k");
	}

	/** Another arm writes a field of the record `value`. */
	public static function fieldSet(r:Verdict):String {
		var value = {x: "d"};
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				value.x = e;
		}
		return "r=" + value.x;
	}
}
