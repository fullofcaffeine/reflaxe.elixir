// Differential fixture o01_nested, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o01_nested
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// Outer binder name is chosen by the compiler (`v` -> value?); inner switch on same enum.
	static function okInOk(a:Verdict, b:Verdict):String {
		return switch (a) {
			case Ok(v):
				switch (b) {
					case Ok(w): v + "+" + w;
					case Error(e): v + "!" + e;
				}
			case Error(x): "outer-err " + x;
		};
	}

	// Same, statement position and moved code after the inner switch.
	static function okInOkMoved(a:Verdict, b:Verdict):String {
		switch (a) {
			case Ok(v):
				switch (b) {
					case Ok(w):
						note(w);
					case Error(e):
						return "inner-err " + e + v;
				}
				return "both " + v;
			case Error(x):
				return "outer-err " + x;
		}
	}

	// Error in Error: both pick `reason`?
	static function errInErr(a:Verdict, b:Verdict):String {
		switch (a) {
			case Error(x):
				switch (b) {
					case Error(y):
						note(y);
					case Ok(o):
						return "ok " + o + x;
				}
				return "errs " + x;
			case Ok(_):
				return "outer-ok";
		}
	}

	// Three levels, all Ok, innermost reads all.
	static function three(a:Verdict, b:Verdict, c:Verdict):String {
		switch (a) {
			case Ok(p):
				switch (b) {
					case Ok(q):
						switch (c) {
							case Ok(r):
								note(r);
							case Error(e):
								return "e3 " + e + p + q;
						}
						return p + q;
					case Error(e):
						return "e2 " + e + p;
				}
			case Error(e):
				return "e1 " + e;
		}
	}

	// Local named function whose own argument is `value`; switch inside with moved code.
	static function localNamed(r:Verdict):String {
		function inner(value:String):String {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					return "err " + e;
			}
			return "r=" + value;
		}
		return inner("LN");
	}

	// Array comprehension whose element is `value`.
	static function comprehension(rs:Array<Verdict>):String {
		var value = "CV";
		var out = [
			for (r in rs)
				switch (r) {
					case Ok(v):
						v + value;
					case Error(e):
						"e" + e + value;
				}
		];
		return out.join(",");
	}

	// Comprehension with loop var named value and moved-ish structure.
	static function comprehensionVar(r:Verdict, values:Array<String>):String {
		var out = [
			for (value in values) {
				var s = switch (r) {
					case Ok(v): v;
					case Error(e): e;
				};
				s + value;
			}
		];
		return out.join(",");
	}

	// while loop with accumulator named value
	static function whileAcc(rs:Array<Verdict>):String {
		var value = "";
		var i = 0;
		while (i < rs.length) {
			switch (rs[i]) {
				case Ok(v):
					note(v);
				case Error(e):
					value += "E" + e;
			}
			value += "|";
			i++;
		}
		return value;
	}

	// Switch inside a call argument with an argument named value
	static function inCallArg(r:Verdict, value:String):String {
		return wrap(switch (r) {
			case Ok(v): "ok " + v;
			case Error(e): "err " + e;
		}, value);
	}

	static function wrap(a:String, b:String):String {
		return "[" + a + "/" + b + "]";
	}

	// Switch in if-condition with moved code
	static function inIfCond(r:Verdict, value:String):String {
		if (switch (r) {
				case Ok(v): v.length > 0;
				case Error(e): false;
			}) {
			return "yes " + value;
			}
		return "no " + value;
	}

	// enum with field named value and reason
	static function fieldNames(r:Named, value:String, reason:String):String {
		switch (r) {
			case Pair(value2, reason2):
				note(value2 + reason2);
			case Single(x):
				return "single " + x;
		}
		return value + reason;
	}

	static function main() {
		for (a in [Ok("A"), Error("X")])
			for (b in [Ok("B"), Error("Y")]) {
				Sys.println("okInOk " + okInOk(a, b));
				Sys.println("okInOkMoved " + okInOkMoved(a, b));
				Sys.println("errInErr " + errInErr(a, b));
				for (c in [Ok("C"), Error("Z")])
					Sys.println("three " + three(a, b, c));
			}
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("localNamed " + localNamed(r));
			Sys.println("comprehensionVar " + comprehensionVar(r, ["1", "2"]));
			Sys.println("inCallArg " + inCallArg(r, "V"));
			Sys.println("inIfCond " + inIfCond(r, "V"));
		}
		Sys.println("comprehension " + comprehension([Ok("o"), Error("x")]));
		Sys.println("whileAcc " + whileAcc([Ok("o"), Error("x"), Ok("p")]));
		Sys.println("fieldNames " + fieldNames(Pair("a", "b"), "V", "R"));
		Sys.println("fieldNames " + fieldNames(Single("s"), "V", "R"));
	}
}

enum Named {
	Pair(value:String, reason:String);
	Single(x:String);
}
