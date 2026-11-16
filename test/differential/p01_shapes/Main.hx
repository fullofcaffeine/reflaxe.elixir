// Differential fixture p01_shapes, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p01_shapes
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var zs = [100, 200];
		var n = 3;
		show("aa", [for (x in xs) for (y in ys) x + y]);
		show("aaa", [for (x in xs) for (y in ys) for (z in zs) x + y + z]);
		show("ar", [for (x in xs) for (i in 0...x) x * 10 + i]);
		show("ra", [for (i in 0...n) for (y in ys) i + y]);
		show("rr", [for (i in 0...n) for (j in i...n) i * 10 + j]);
		show("f_outer", [for (x in xs) if (x != 2) for (y in ys) x + y]);
		show("f_inner", [
			for (x in xs)
				for (y in ys)
					if (x * y > 20)
						x * y
		]);
		show("f_both", [
			for (x in xs)
				if (x > 1) for (y in ys)
					if (y > 10)
						x * y
		]);
		show("aa_str", [for (x in ["a", "b"]) for (y in ["c", "d"]) x + y]);
		var stored = [for (x in xs) for (y in ys) x * y];
		show("stored_len", [stored.length]);
		show("stored", stored);
		show("empty_outer", [for (x in []) for (y in ys) x + y]);
		show("empty_inner", [for (x in xs) for (y in ([] : Array<Int>)) x + y]);
		show("aa_then_aa", [for (x in xs) for (y in ys) x - y].concat([for (x in ys) for (y in xs) x - y]));
		show("block_body", [
			for (x in xs)
				for (y in ys) {
					var t = x * y;
					t + 1;
				}
		]);
	}
}
