// Differential fixture o08_reraise_shapes, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o08_reraise_shapes
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// Statement position: try with a typed catch inside an Error arm.
	static function stmt(r:Verdict, code:Int):String {
		var out = "start";
		switch (r) {
			case Error(e):
				try {
					if (code > 0)
						throw code;
					out = "no throw " + e;
				} catch (s:String) {
					out = "caught " + s + e;
				}
			case Ok(v):
				out = "ok " + v;
		}
		return out;
	}

	// Typed catch of a class, payload used in body.
	static function classCatch(r:Verdict, code:Int):String {
		switch (r) {
			case Error(e):
				try {
					throw code;
				} catch (ex:haxe.Exception) {
					note("ex " + e);
				}
				return "after " + e;
			case Ok(v):
				return "ok " + v;
		}
	}

	// Rethrow explicitly from inside an Error arm.
	static function explicitRethrow(r:Verdict):String {
		switch (r) {
			case Error(e):
				try {
					throw "boom " + e;
				} catch (s:String) {
					note(s);
					throw s;
				}
			case Ok(v):
				return "ok " + v;
		}
	}

	static function guard(label:String, f:() -> String):Void {
		try {
			Sys.println(label + " returned " + Std.string(f()));
		} catch (n:Int) {
			Sys.println(label + " outer caught int " + n);
		} catch (s:String) {
			Sys.println(label + " outer caught string " + s);
		}
	}

	static function main() {
		guard("stmt0", () -> stmt(Error("x"), 0));
		guard("stmt5", () -> stmt(Error("x"), 5));
		guard("stmtOk", () -> stmt(Ok("o"), 5));
		guard("classCatch", () -> classCatch(Error("x"), 7));
		guard("explicitRethrow", () -> explicitRethrow(Error("x")));
		Sys.println("done");
	}
}
