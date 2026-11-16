// Differential fixture o09_residual, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o09_residual
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// Comprehension: Error arm reads the generator variable (maybe an Elixir `for`).
	static function compGen(r:Verdict, values:Array<String>):String {
		return [
			for (value in values)
				switch (r) {
					case Error(e):
						value + "/" + e;
					case Ok(_):
						"ok";
				}
		].join(",");
	}

	// Comprehension with Error arm whose payload is unused, reading only the generator var.
	static function compGenOnly(r:Verdict, values:Array<String>):String {
		return [
			for (item in values)
				switch (r) {
					case Error(_):
						"E" + item;
					case Ok(o):
						o;
				}
		].join(",");
	}

	// Two generators.
	static function compTwo(r:Verdict, xs:Array<String>, ys:Array<String>):String {
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

	// Rethrow the caught exception from inside an Error arm.
	static function rethrowEx(r:Verdict):String {
		try {
			throw new haxe.Exception("boom");
		} catch (ex:haxe.Exception) {
			switch (r) {
				case Error(e):
					note("err " + e);
					throw ex;
				case Ok(v):
					return "ok " + v;
			}
		}
	}

	// Catch binder read inside an Error arm (catch binder is a case pattern).
	static function catchRead(r:Verdict):String {
		try {
			throw "boom";
		} catch (s:String) {
			return switch (r) {
				case Error(e): s + "/" + e;
				case Ok(v): v;
			};
		}
	}

	// Error arm inside an untyped (Dynamic) catch, reading the caught value.
	static function dynCatch(r:Verdict):String {
		try {
			throw 42;
		} catch (d:Dynamic) {
			return switch (r) {
				case Error(e): Std.string(d) + "/" + e;
				case Ok(v): v;
			};
		}
	}

	// Error arm in a catch, payload unused, reads only the catch value.
	static function catchOnly(r:Verdict):String {
		try {
			throw "boom";
		} catch (s:String) {
			return switch (r) {
				case Error(_): "E" + s;
				case Ok(v): v;
			};
		}
	}

	static function guard(label:String, f:() -> String):Void {
		try {
			Sys.println(label + " " + f());
		} catch (ex:haxe.Exception) {
			Sys.println(label + " outer caught " + ex.message);
		}
	}

	static function main() {
		for (r in [Ok("o"), Error("x")]) {
			guard("compGen", () -> compGen(r, ["a", "b"]));
			guard("compGenOnly", () -> compGenOnly(r, ["a", "b"]));
			guard("compTwo", () -> compTwo(r, ["a", "b"], ["1", "2"]));
			guard("rethrowEx", () -> rethrowEx(r));
			guard("catchRead", () -> catchRead(r));
			guard("dynCatch", () -> dynCatch(r));
			guard("catchOnly", () -> catchOnly(r));
		}
		Sys.println("done");
	}
}
