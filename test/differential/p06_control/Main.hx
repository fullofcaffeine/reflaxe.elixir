// Differential fixture p06_control, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p06_control
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3, 4];
		var ys = [10, 20, 30];
		var out:Array<Int> = [];
		for (x in xs) {
			if (x == 2)
				continue;
			for (y in ys) {
				if (y == 20)
					continue;
				if (x == 4)
					break;
				out.push(x + y);
			}
		}
		show("stmt_break_continue", out);
		var out2:Array<Int> = [];
		for (x in xs) {
			for (y in ys) {
				if (y > 10 * x)
					break;
				out2.push(x * y);
			}
			if (x == 3)
				break;
		}
		show("stmt_break_outer", out2);
	}
}
