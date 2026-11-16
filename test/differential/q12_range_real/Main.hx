// Differential fixture q12_range_real, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q12_range_real
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	// plain local name: no tracked seed involved
	static function plainRangeThenWhile(n:Int):Array<Int> {
		var acc:Array<Int> = [];
		for (i in 0...n) {
			var j = 0;
			while (j < 2) {
				acc.push(i * 10 + j);
				j++;
			}
		}
		for (i in 0...n)
			acc.push(i + 100);
		var t = 0;
		while (t < 2) {
			acc.push(t + 200);
			t++;
		}
		return acc;
	}

	static function main() {
		var n = [7, 8, 9].length;
		var xs = [1, 2];
		var im = [1 => "one", 2 => "two"];
		var flags = [true, false];
		show("plainRangeThenWhile", plainRangeThenWhile(n));
		// comprehension temps: unrolled outer range, arms of different loop kinds
		show("c_range_then_keys", [
			for (a in 0...2)
				if (a == 0) for (i in 0...n) i else for (k in im.keys()) k + 100
		]);
		show("c_keys_then_range", [
			for (a in 0...2)
				if (a == 1) for (i in 0...n) i else for (k in im.keys()) k + 100
		]);
		show("c_flags_range_keys", [
			for (a in 0...2)
				if (flags[a]) for (i in 0...n) i else for (k in im.keys()) k + 100
		]);
		show("c_flags_keys_range", [
			for (a in 0...2)
				if (!flags[a]) for (i in 0...n) i else for (k in im.keys()) k + 100
		]);
		show("c_flags_for_keys", [for (a in 0...2) if (flags[a]) for (x in xs) x else for (k in im.keys()) k + 100]);
		show("c_flags_rangekeys_keys", [
			for (a in 0...2)
				if (flags[a]) for (i in 0...n) for (k in im.keys()) i * 10 + k else for (k in im.keys()) k + 100
		]);
		show("c_range_keys", [for (i in 0...n) for (k in im.keys()) i * 10 + k]);
		show("c_keys_range", [for (k in im.keys()) for (i in 0...n) i * 10 + k]);
		show("c_r_range_keys", [for (a in 0...2) for (i in 0...n) for (k in im.keys()) a * 100 + i * 10 + k]);
		show("c_r_keys_range", [for (a in 0...2) for (k in im.keys()) for (i in 0...n) a * 100 + i * 10 + k]);
	}
}
