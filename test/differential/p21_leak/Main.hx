// Differential fixture p21_leak, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p21_leak
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
		show("r_a_keys", [for (i in 0...2) for (x in xs) for (k in im.keys()) i * 100 + x * 10 + k]);
		show("r_keys_a", [for (i in 0...2) for (k in im.keys()) for (x in xs) i * 100 + k * 10 + x]);
		show("a_keys_then", [for (x in xs) for (k in im.keys()) x * 10 + k]);
		show("two_in_a_row", [for (k in m.keys()) k].concat([for (k in m.keys()) k + "!"]));
		var c = true;
		var r1 = if (c) [for (k in m.keys()) for (x in xs) k + x] else [];
		var r2 = [for (k in m.keys()) k + "2"];
		show("if_then", r1);
		show("after_if", r2);
		var f = () -> [for (k in m.keys()) for (x in xs) k + x];
		show("closure", f());
		show("closure_again", f());
		show("comp_closure_comp", [for (k in m.keys()) (() -> [for (j in im.keys()) k + j].length) ()]);
		show("while_body", [
			for (k in m.keys()) {
				var s = 0;
				while (s < 2)
					s++;
				k + s;
			}
		]);
		var out:Array<String> = [];
		for (k in m.keys())
			out.push(k);
		var n = 0;
		while (n < 2) {
			out.push("w" + n);
			n++;
		}
		show("stmt_then_while", out);
		var acc:Array<Int> = [];
		for (i in 0...2)
			for (k in im.keys())
				acc.push(i * 10 + k);
		for (k in im.keys())
			acc.push(k * 100);
		show("stmt_unrolled_then", acc);
	}
}
