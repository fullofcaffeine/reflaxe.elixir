// Differential fixture o07_reraise, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o07_reraise
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	// Error arm holds a try whose catch does not match the thrown value.
	// Haxe: the Int propagates to the caller's catch.
	static function errArmRethrow(r:Verdict, code:Int):String {
		return switch (r) {
			case Error(e):
				try {
					throw code;
				} catch (reason:String) {
					reason + e;
				}
			case Ok(_):
				"ok";
		};
	}

	static function main() {
		try {
			var s = errArmRethrow(Error("x"), 5);
			Sys.println("returned " + Std.string(s));
		} catch (n:Int) {
			Sys.println("outer caught " + n);
		}
		Sys.println("done");
	}
}
