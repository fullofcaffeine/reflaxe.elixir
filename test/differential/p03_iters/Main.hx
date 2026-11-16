// Differential fixture p03_iters, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p03_iters
class Countdown {
	var n:Int;

	public function new(n:Int)
		this.n = n;

	public function hasNext():Bool
		return n > 0;

	public function next():Int
		return n--;
}

class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		show("a_iter", [for (x in xs) for (y in xs.iterator()) x * 10 + y]);
		show("a_custom", [for (x in xs) for (c in new Countdown(x)) x * 10 + c]);
		show("custom_a", [for (c in new Countdown(2)) for (x in xs) c * 10 + x]);
		show("a_kvarr", [for (x in xs) for (i => v in xs) x * 100 + i * 10 + v]);
		show("a_str", [for (x in xs) for (ch in "ab".split("")) ch + x]);
	}
}
