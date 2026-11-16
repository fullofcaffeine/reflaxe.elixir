// Differential fixture p02_maps, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p02_maps
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function main() {
		var xs = [1, 2];
		var m = ["a" => 1, "b" => 2];
		var im = [1 => "one", 2 => "two"];
		show("a_keys", [for (x in xs) for (k in m.keys()) k + x]);
		show("a_vals", [for (x in xs) for (v in m) v * 10 + x]);
		show("a_kv", [for (x in xs) for (k => v in m) k + (v + x)]);
		show("keys_a", [for (k in m.keys()) for (x in xs) k + x]);
		show("keys_keys", [for (k in m.keys()) for (j in im.keys()) k + j]);
		show("keys_filter", [
			for (x in xs) for (k in m.keys()) if (m.get(k) != x)
				k + x
		]);
		show("aaa_keys", [for (x in xs) for (y in xs) for (k in m.keys()) k + x + y]);
		show("r_keys", [for (i in 0...2) for (k in im.keys()) i * 10 + k]);
	}
}
