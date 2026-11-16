// Differential fixture p25_gcomp, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p25_gcomp
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function main() {
		var xs = [1, 2];
		var flags = [true, false];
		var im = [1 => "one", 2 => "two"];
		show("r_if_else", [
			for (i in 0...2)
				if (flags[i]) for (x in xs) for (k in im.keys()) x * 10 + k else for (k in im.keys()) k + 100
		]);
	}
}
