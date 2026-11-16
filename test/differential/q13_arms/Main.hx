// Differential fixture q13_arms, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q13_arms
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function compInWhile(im:Map<Int, String>):Array<Int> {
		var out:Array<Int> = [];
		var i = 0;
		while (i < 2) {
			out = out.concat([for (a in 0...2) for (k in im.keys()) k + a * 10 + i * 100]);
			i++;
		}
		var j = 0;
		while (j < 2) {
			out = out.concat([for (k in im.keys()) for (q in im.keys()) k * 10 + q + j * 1000]);
			j++;
		}
		return out;
	}

	static function compInKv(m:Map<String, Int>, im:Map<Int, String>):Array<String> {
		var out:Array<String> = [];
		for (k => v in m)
			out = out.concat([for (a in 0...2) for (j in im.keys()) k + v + a + j]);
		return out;
	}

	static function parse(k:String):Int {
		if (k == "b")
			throw "bad";
		return k.length;
	}

	static function main() {
		var xs = [1, 2];
		var m = ["a" => 1, "b" => 2];
		var im = [1 => "one", 2 => "two"];
		show("if3_arms", [
			for (i in 0...3)
				if (i == 0) for (k in im.keys()) k else if (i == 1) for (x in xs) for (k in im.keys()) k + x * 10 else for (x in xs) x + 500
		]);
		show("if3_arms_rev", [
			for (i in 0...3)
				if (i == 2) for (k in im.keys()) k else if (i == 1) for (x in xs) for (k in im.keys()) k + x * 10 else for (x in xs) x + 500
		]);
		show("try_elem", [
			for (i in 0...2)
				for (k in m.keys())
					try
						parse(k) + i
					catch (e:String)
						-1]);
		show("break_inner", [
			for (x in xs)
				for (k in im.keys()) {
					if (k > 1)
						break;
					x * 10 + k;
				}
		]);
		show("continue_keys", [
			for (k in im.keys())
				for (x in xs) {
					if (x == 1)
						continue;
					x * 10 + k;
				}
		]);
		show("r_in_r", [
			for (i in 0...2)
				for (v in [for (a in 0...2) for (k in im.keys()) k + a * 10])
					v + i * 100
		]);
		show("compInWhile", compInWhile(im));
		show("compInKv", compInKv(m, im));
		show("r4", [for (i in 0...4) for (k in im.keys()) i * 10 + k]);
		show("r_kv", [for (i in 0...2) for (k => v in m) k + v + i]);
		show("kv_r_kv", [for (k => v in m) for (i in 0...2) for (j => w in im) k + v + i + j + w]);
	}
}
