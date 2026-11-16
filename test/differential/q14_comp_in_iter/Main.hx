// Differential fixture q14_comp_in_iter, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q14_comp_in_iter
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function main() {
		var xs = [1, 2];
		var im = [1 => "one", 2 => "two"];
		// inner comprehension as the iterable of an inner clause; outer values differ from inner values
		show("r_in_r", [
			for (i in 0...2) for (v in [for (a in 0...2) for (k in im.keys()) k + a * 10]) v + (i + 1) * 100
		]);
		show("for_in_keys", [for (x in xs) for (v in [for (k in im.keys()) k]) v + x * 100]);
		show("keys_in_keys", [for (j in im.keys()) for (v in [for (k in im.keys()) k]) v + j * 100]);
		show("r_in_keys", [for (i in 0...2) for (v in [for (k in im.keys()) k]) v + (i + 1) * 100]);
		show("for_in_for", [for (x in xs) for (v in [for (y in xs) y]) v + x * 100]);
	}
}
