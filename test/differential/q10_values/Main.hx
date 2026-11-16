// Differential fixture q10_values, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q10_values
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static inline function keysOf(m:Map<String, Int>):Array<String>
		return [for (k in m.keys()) k];

	static function inlineTwice(m:Map<String, Int>, xs:Array<Int>):Array<String> {
		var a = keysOf(m);
		var out:Array<String> = [];
		for (x in xs)
			for (k in keysOf(m))
				out.push(k + x);
		return a.concat(out);
	}

	static function valueIf(c:Bool, m:Map<String, Int>):Array<String> {
		var r = if (c) [for (k in m.keys()) k] else [for (i in 0...2) for (k in m.keys()) k + i];
		return [for (k in r) for (j in m.keys()) k + j];
	}

	static function localFn(m:Map<String, Int>, im:Map<Int, String>):Array<Int> {
		return [
			for (k in m.keys()) {
				var f = function() return [for (i in 0...2) for (j in im.keys()) j + i];
				f().length + k.length;
			}
		];
	}

	static function tryComp(m:Map<String, Int>):Array<Int> {
		return [
			for (k in m.keys()) try {
				if (k == "b")
					throw "x";
				m.get(k);
			} catch (e:String)
				-1
		];
	}

	static function breakInComp(xs:Array<Int>, m:Map<String, Int>):Array<String> {
		return [
			for (x in xs) {
				if (x > 2) break;
				for (k in m.keys())
					k + x;
			}
		].map(a -> Std.string(a));
	}

	static function compOfComps(m:Map<String, Int>, im:Map<Int, String>):Array<Int> {
		var rows = [for (k in m.keys()) [for (i in 0...2) for (j in im.keys()) i * 10 + j]];
		var out:Array<Int> = [];
		for (r in rows)
			for (v in r)
				out.push(v);
		return out;
	}

	static function switchVal(k:Int, m:Map<String, Int>, im:Map<Int, String>):Array<String> {
		var r = switch (k) {
			case 0: [for (a in m.keys()) a];
			case 1: [for (i in 0...2) for (a in m.keys()) for (j in im.keys()) a + i + j];
			default: [for (a in m.keys()) for (b in m.keys()) a + b];
		};
		var extra = [for (i in 0...2) for (a in m.keys()) a + "e" + i];
		return r.concat(extra);
	}

	static function main() {
		var m = ["a" => 1, "b" => 2];
		var im = [1 => "one", 2 => "two"];
		show("inlineTwice", inlineTwice(m, [1, 2]));
		show("valueIf_t", valueIf(true, m));
		show("valueIf_f", valueIf(false, m));
		show("localFn", localFn(m, im));
		show("tryComp", tryComp(m));
		show("compOfComps", compOfComps(m, im));
		show("switchVal0", switchVal(0, m, im));
		show("switchVal1", switchVal(1, m, im));
		show("switchVal2", switchVal(2, m, im));
	}
}
