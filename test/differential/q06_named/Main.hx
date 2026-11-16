// Differential fixture q06_named, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q06_named
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function chain(m:Map<String, Int>, im:Map<Int, String>):Array<String> {
		var keys = [for (k in m.keys()) k];
		var more = [for (k in keys) for (j in im.keys()) k + j];
		var third = [for (k in m.keys()) k + "3"];
		return keys.concat(more).concat(third);
	}

	static function namedThenPush(m:Map<String, Int>):Array<String> {
		var keys = [for (k in m.keys()) k];
		for (k in m.keys())
			keys.push(k + "+");
		var i = 0;
		while (i < 2) {
			keys.push("w" + i);
			i++;
		}
		return keys;
	}

	static function unusedNamed(m:Map<String, Int>):Int {
		var keys = [for (k in m.keys()) k];
		var vals = [for (v in m) v];
		return vals.length;
	}

	static function tupleReturn(m:Map<String, Int>):Int {
		var total = 0;
		var keys = [
			for (k in m.keys()) {
				total += m.get(k);
				k;
			}
		];
		return total * 10 + keys.length;
	}

	static function compInIf(c:Bool, m:Map<String, Int>):Array<String> {
		var r:Array<String>;
		if (c)
			r = [for (k in m.keys()) k + "t"];
		else
			r = [for (k in m.keys()) for (j in m.keys()) k + j];
		var more = [for (k in m.keys()) k + "m"];
		return r.concat(more);
	}

	static function compArgs(m:Map<String, Int>):Array<String> {
		return [for (k in m.keys()) k + "x"].concat([for (k in m.keys()) k + "y"]);
	}

	static function main() {
		var m = ["a" => 1, "b" => 2];
		var im = [1 => "one", 2 => "two"];
		show("chain", chain(m, im));
		show("namedThenPush", namedThenPush(m));
		show("unusedNamed", [unusedNamed(m)]);
		show("tupleReturn", [tupleReturn(m)]);
		show("compInIf_t", compInIf(true, m));
		show("compInIf_f", compInIf(false, m));
		show("compArgs", compArgs(m));
	}
}
