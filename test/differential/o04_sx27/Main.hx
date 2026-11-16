// Differential fixture o04_sx27, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o04_sx27
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// Error arm containing a closure whose arg is named value
	static function errClosure(a:Verdict, items:Array<String>):String {
		return switch (a) {
			case Error(m): items.map(function(value) return value + m).join(",");
			case Ok(o): "ok " + o;
		};
	}

	// Error arm with loop whose var is value, reading outer payload
	static function errLoop(a:Verdict, items:Array<String>):String {
		switch (a) {
			case Error(m):
				var acc = "";
				for (value in items)
					acc += value + m;
				return acc;
			case Ok(o):
				return "ok " + o;
		}
	}

	// Error arm with nested Error switch and moved code reading both
	static function errErrMoved(a:Verdict, b:Verdict):String {
		switch (a) {
			case Error(m):
				switch (b) {
					case Error(n):
						note(n);
					case Ok(_):
						return "inner-ok " + m;
				}
				return "both-err " + m;
			case Ok(_):
				return "outer-ok";
		}
	}

	// Error arm with try/catch inside
	static function errTry(a:Verdict):String {
		switch (a) {
			case Error(m):
				try {
					throw "t" + m;
				} catch (value:String) {
					return "caught " + value + m;
				}
			case Ok(o):
				return "ok " + o;
		}
	}

	// Ok inside Error where outer payload unused but inner reads its own
	static function okInErrUnused(a:Verdict, b:Verdict):Int {
		return switch (a) {
			case Error(_): switch (b) {
					case Ok(v): v.length;
					case Error(x): x.length * 10;
				};
			case Ok(_): -1;
		};
	}

	static function main() {
		for (a in [Ok("A"), Error("XY")]) {
			Sys.println("errClosure " + errClosure(a, ["1", "2"]));
			Sys.println("errLoop " + errLoop(a, ["1", "2"]));
			Sys.println("errTry " + errTry(a));
			for (b in [Ok("BBB"), Error("YYYY")]) {
				Sys.println("errErrMoved " + errErrMoved(a, b));
				Sys.println("okInErrUnused " + okInErrUnused(a, b));
			}
		}
	}
}
