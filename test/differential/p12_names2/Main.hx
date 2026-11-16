// Differential fixture p12_names2, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p12_names2
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var g = 1000;
		var acc = 5;
		show("reads_g", [for (x in xs) for (y in ys) x + y + g]);
		show("reads_acc", [for (x in xs) for (y in ys) x + y + acc]);
		var out = [];
		for (x in xs)
			for (y in ys)
				out.push(x + y + out.length);
		show("stmt_reads_out", out);
		var out2:Array<Int> = [];
		for (x in xs) {
			out2.push(x);
			for (y in ys)
				out2.push(out2.length * 100 + y);
		}
		show("stmt_push_both", out2);
		var r = [for (x in xs) for (y in ys) x + y];
		var r2 = [
			for (x in r)
				for (y in r)
					if (x == y)
						x
		];
		show("chained", r2);
		show("after", [g, acc]);
	}
}
