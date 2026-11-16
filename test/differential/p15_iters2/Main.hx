// Differential fixture p15_iters2, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p15_iters2
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function main() {
		var xs = [1, 2, 3];
		var m = ["a" => 1, "b" => 2];
		show("a_kvarr", [for (x in xs) for (i => v in xs) x * 100 + i * 10 + v]);
		show("a_str", [for (x in xs) for (ch in "ab".split("")) ch + x]);
		var out:Array<String> = [];
		for (k in m.keys())
			for (x in xs)
				out.push(k + x);
		show("stmt_keys_a", out);
		var out2:Array<String> = [];
		for (k in m.keys())
			for (j in m.keys())
				out2.push(k + j);
		show("stmt_keys_keys", out2);
		var n = 0;
		for (k in m.keys())
			for (x in xs)
				n += x;
		show("stmt_keys_count", [n]);
		var out3:Array<Int> = [];
		for (i in 0...2)
			for (k in m.keys())
				out3.push(i * 10 + m.get(k));
		show("stmt_r_keys", out3);
	}
}
