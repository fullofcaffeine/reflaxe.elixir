// Differential fixture o06_inner, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o06_inner
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// arm declares a local named like the canonical binder, then reads the payload
	static function armLocal(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				var value = "x";
				note(value);
				v + value;
			case Error(e):
				var reason = "y";
				note(reason);
				e + reason;
		};
	}

	// arm loop var named value reading payload inside loop
	static function armLoop(r:Verdict, items:Array<String>):String {
		var out = "";
		switch (r) {
			case Ok(v):
				for (value in items)
					out += value + v;
			case Error(e):
				for (reason in items)
					out += reason + e;
		}
		return out;
	}

	// arm closure arg named value reading payload
	static function armClosure(r:Verdict, items:Array<String>):String {
		return switch (r) {
			case Ok(v): items.map(function(value) return value + v).join(",");
			case Error(e): items.map(function(reason) return reason + e).join(",");
		};
	}

	// arm try/catch var named value reading payload
	static function armCatch(r:Verdict):String {
		return switch (r) {
			case Ok(v):
				try {
					throw "T";
				} catch (value:String) {
					value + v;
				}
			case Error(e):
				try {
					throw "U";
				} catch (reason:String) {
					reason + e;
				}
		};
	}

	// inner switch on a different enum whose fields are value/reason, in an Ok arm
	static function innerOther(r:Verdict, n:Named):String {
		return switch (r) {
			case Ok(v):
				switch (n) {
					case Pair(a, b): a + b + v;
					case Single(x): x + v;
				}
			case Error(e): "e" + e;
		};
	}

	// moved code after switch inside an if branch that is itself inside a loop
	static function deepMoved(rs:Array<Verdict>, value:String):String {
		var out = "";
		for (r in rs) {
			if (out.length < 100) {
				switch (r) {
					case Ok(v):
						note(v);
					case Error(e):
						out += "E" + e;
						continue;
				}
				out += value;
			}
		}
		return out;
	}

	static function main() {
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("armLocal " + armLocal(r));
			Sys.println("armLoop " + armLoop(r, ["1", "2"]));
			Sys.println("armClosure " + armClosure(r, ["1", "2"]));
			Sys.println("armCatch " + armCatch(r));
			Sys.println("innerOther " + innerOther(r, Pair("a", "b")) + " " + innerOther(r, Single("s")));
		}
		Sys.println("deepMoved " + deepMoved([Ok("o"), Error("x"), Ok("p")], "V"));
	}
}

enum Named {
	Pair(value:String, reason:String);
	Single(value:String);
}
