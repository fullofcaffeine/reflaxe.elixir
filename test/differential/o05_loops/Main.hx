// Differential fixture o05_loops, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o05_loops
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// key-value iteration: key and value names
	static function keyValue(m:Map<String, Verdict>):String {
		var keys = [for (k in m.keys()) k];
		keys.sort((a, b) -> a < b ? -1 : 1);
		var out = "";
		for (key in keys) {
			var value = key + "!";
			switch (m.get(key)) {
				case Ok(v):
					note(v);
				case Error(e):
					out += "E" + e + value;
					continue;
				case null:
					continue;
			}
			out += value;
		}
		return out;
	}

	// array key-value iteration
	static function arrayKV(rs:Array<Verdict>):String {
		var out = "";
		for (value => r in rs) {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					out += "E" + e;
					continue;
			}
			out += "i" + value;
		}
		return out;
	}

	// nested loops, inner loop var value, break
	static function nestedLoops(rs:Array<Verdict>, items:Array<String>):String {
		var out = "";
		for (r in rs) {
			for (value in items) {
				switch (r) {
					case Ok(v):
						note(v);
					case Error(e):
						out += "E" + e;
						break;
				}
				out += value;
			}
		}
		return out;
	}

	// range loop var named reason (int)
	static function rangeReason(r:Verdict, n:Int):String {
		var out = "";
		for (reason in 0...n) {
			switch (r) {
				case Error(e):
					note(e);
				case Ok(o):
					out += "o" + o;
					continue;
			}
			out += "r" + reason;
		}
		return out;
	}

	// do-while with value accumulator, switch inside
	static function doWhile(rs:Array<Verdict>):String {
		var value = "";
		var i = 0;
		do {
			switch (rs[i]) {
				case Ok(v):
					note(v);
				case Error(e):
					i++;
					continue;
			}
			value += "#" + i;
			i++;
		} while (i < rs.length);
		return value;
	}

	// Loop body closure capturing loop var
	static function loopClosure(rs:Array<Verdict>, items:Array<String>):String {
		var fs:Array<() -> String> = [];
		for (value in items) {
			fs.push(function() {
				switch (rs[0]) {
					case Ok(v):
						note(v);
					case Error(e):
						return "E" + e;
				}
				return "c" + value;
			});
		}
		return [for (f in fs) f()].join(",");
	}

	static function main() {
		var m = new Map<String, Verdict>();
		m.set("a", Ok("o"));
		m.set("b", Error("x"));
		Sys.println("keyValue " + keyValue(m));
		Sys.println("arrayKV " + arrayKV([Ok("o"), Error("x"), Ok("p")]));
		Sys.println("nestedLoops " + nestedLoops([Ok("o"), Error("x")], ["1", "2"]));
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("rangeReason " + rangeReason(r, 3));
			Sys.println("loopClosure " + loopClosure([r], ["1", "2"]));
		}
		Sys.println("doWhile " + doWhile([Ok("o"), Error("x"), Ok("p")]));
	}
}
