// Differential fixture o10_okcatch, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o10_okcatch
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	// Ok arm: typed catch reads the payload.
	static function okCatchValue(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (s:String) {
					s + v;
				}
			case Error(e):
				"e" + e;
		};
	}

	// Ok arm, statement position, payload read after the try.
	static function okCatchAfter(r:Verdict):String {
		switch (r) {
			case Ok(v):
				var out = "";
				try {
					throw "T";
				} catch (s:String) {
					out = s;
				}
				return out + v;
			case Error(e):
				return "e" + e;
		}
	}

	static function main() {
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("okCatchValue " + okCatchValue(r));
			Sys.println("okCatchAfter " + okCatchAfter(r));
		}
	}
}
