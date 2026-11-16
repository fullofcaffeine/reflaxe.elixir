// Differential fixture p14_rows, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p14_rows
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function grid(n:Int, m:Int):Array<Array<Int>> {
		var rows = [];
		for (i in 0...n) {
			var row = [];
			for (j in 0...m)
				row.push(i * m + j);
			rows.push(row);
		}
		return rows;
	}

	static function main() {
		show("grid", grid(3, 2).map(r -> r.join("/")));
		var xs = [1, 2, 3];
		var evens = 0;
		var pairs:Array<String> = [];
		for (x in xs)
			for (y in xs) {
				if ((x + y) % 2 == 0) {
					evens++;
					pairs.push(x + "" + y);
				}
			}
		show("evens", [evens]);
		show("pairs", pairs);
		var tri = [for (i in 0...4) [for (j in 0...i) j]];
		show("tri", tri.map(r -> r.length));
		var prod = [for (row in grid(2, 2)) for (v in row) v * v];
		show("prod", prod);
		var cnt = 0;
		var r3 = [
			for (x in xs)
				for (y in xs)
					for (z in xs)
						if (x < y && y < z) {
							cnt++;
							x * 100 + y * 10 + z;
						}
		];
		show("r3", r3);
		show("cnt", [cnt]);
	}
}
