// Differential fixture q05_unrolled, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q05_unrolled
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function twoComps(im:Map<Int, String>):Array<Int> {
		var a = [for (i in 0...2) for (k in im.keys()) k + i];
		var b = [for (i in 0...2) for (k in im.keys()) k * 10 + i];
		return a.concat(b);
	}

	static function compThenLoop(im:Map<Int, String>, xs:Array<Int>):Array<Int> {
		var a = [for (i in 0...2) for (k in im.keys()) k + i];
		for (x in xs)
			a.push(x * 1000);
		var j = 0;
		while (j < 2) {
			a.push(j * 10000);
			j++;
		}
		return a;
	}

	static function main() {
		var xs = [1, 2];
		var im = [1 => "one", 2 => "two"];
		var em = new Map<Int, String>();
		show("r3", [for (i in 0...3) for (k in im.keys()) i * 10 + k]);
		show("r2r2", [for (i in 0...2) for (j in 0...2) for (k in im.keys()) i * 100 + j * 10 + k]);
		show("r_keys_keys", [for (i in 0...2) for (k in im.keys()) for (j in im.keys()) i * 100 + k * 10 + j]);
		show("keys_r_keys", [for (k in im.keys()) for (i in 0...2) for (j in im.keys()) i * 100 + k * 10 + j]);
		show("for_r_keys", [for (x in xs) for (i in 0...2) for (k in im.keys()) x * 100 + i * 10 + k]);
		show("r_arms", [for (i in 0...2) if (i == 0) for (k in im.keys()) k else for (x in xs) x + 50]);
		show("r_arms2", [for (i in 0...2) if (i == 1) for (k in im.keys()) k else for (x in xs) x + 50]);
		show("r_filter", [for (i in 0...3) if (i != 1) for (k in im.keys()) i * 10 + k]);
		show("r_empty", [for (i in 0...3) for (k in em.keys()) i * 10 + k]);
		show("r_for_only", [for (i in 0...2) for (x in xs) i * 10 + x]);
		show("r_for_keys_mix", [for (i in 0...2) for (x in xs) for (k in im.keys()) i * 100 + x * 10 + k]);
		show("twoComps", twoComps(im));
		show("compThenLoop", compThenLoop(im, xs));
		show("r_block", [
			for (i in 0...2) {
				var acc = 0;
				for (k in im.keys())
					acc += k;
				acc + i;
			}
		]);
		show("nested_comp", [for (i in 0...2) [for (k in im.keys()) k + i].length]);
	}
}
