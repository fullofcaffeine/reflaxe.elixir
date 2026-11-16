// Differential fixture o11_unused_catch, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o11_unused_catch
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	// Error arm, payload unused, typed catch that must rethrow an Int.
	static function errUnused(r:Verdict, code:Int):String {
		return switch (r) {
			case Error(_):
				try {
					throw code;
				} catch (s:String) {
					"caught " + s;
				}
			case Ok(v):
				"ok " + v;
		};
	}

	// Ok arm, payload unused, typed catch that must rethrow an Int.
	static function okUnused(r:Verdict, code:Int):String {
		return switch (r) {
			case Ok(_):
				try {
					throw code;
				} catch (s:String) {
					"caught " + s;
				}
			case Error(e):
				"err " + e;
		};
	}

	// Error arm inside a closure whose argument is named reason, payload unused, typed catch.
	static function closureErr(r:Verdict, code:Int):String {
		var f = function(reason:String):String {
			return switch (r) {
				case Error(_):
					try {
						throw code;
					} catch (s:String) {
						s + reason;
					}
				case Ok(v):
					v + reason;
			};
		};
		return f("R");
	}

	// Ok arm inside a closure whose argument is named value, payload unused, typed catch.
	static function closureOk(r:Verdict, code:Int):String {
		var f = function(value:String):String {
			return switch (r) {
				case Ok(_):
					try {
						throw code;
					} catch (s:String) {
						s + value;
					}
				case Error(e):
					e + value;
			};
		};
		return f("V");
	}

	// Payload used, catch reads payload, catch binder named like the canonical name.
	static function okCatchNamedValue(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (value:String) {
					value + v;
				}
			case Error(e):
				"e" + e;
		};
	}

	static function guard(label:String, f:() -> String):Void {
		try {
			Sys.println(label + " returned " + Std.string(f()));
		} catch (n:Int) {
			Sys.println(label + " outer caught int " + n);
		}
	}

	static function main() {
		for (r in [Ok("o"), Error("x")]) {
			guard("errUnused", () -> errUnused(r, 5));
			guard("okUnused", () -> okUnused(r, 5));
			guard("closureErr", () -> closureErr(r, 5));
			guard("closureOk", () -> closureOk(r, 5));
		}
		guard("okCatchNamedValue", () -> okCatchNamedValue(Ok("o")));
		Sys.println("done");
	}
}
