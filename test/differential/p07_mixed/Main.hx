// Differential fixture p07_mixed, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p07_mixed
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var log:Array<String> = [];
		var r = [
			for (x in xs) for (y in ys) {
				log.push(x + ":" + y);
				x + y;
			}
		];
		show("r", r);
		show("log", log);
		var total = 0;
		var r2 = [
			for (x in xs) for (y in ys) {
				total += x * y;
				total;
			}
		];
		show("r2", r2);
		show("total", [total]);
		var count = 0;
		for (x in xs)
			for (y in ys)
				count += x * y;
		show("count", [count]);
		var s = "";
		for (x in xs)
			for (i in 0...x)
				s += Std.string(i);
		show("s", [s]);
	}
}
