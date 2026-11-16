// Differential fixture p04_scopes, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p04_scopes
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function pick(k:Int, xs:Array<Int>, ys:Array<Int>):Array<Int> {
		return switch (k) {
			case 0: [for (x in xs) for (y in ys) x + y];
			case 1: [for (x in xs) for (y in ys) x * y];
			default: [];
		};
	}

	static function tryIt(xs:Array<Int>, ys:Array<Int>):Array<Int> {
		try {
			var r = [
				for (x in xs)
					for (y in ys)
						if (y == 0)
							throw "zero"
						else
							x * y
			];
			return r;
		} catch (e:String) {
			return [-1];
		}
	}

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var f = () -> [for (x in xs) for (y in ys) x + y];
		show("closure", f());
		var g = (k:Int) -> [for (x in xs) for (y in ys) x * k + y];
		show("closure_arg", g(5));
		show("map_cb", xs.map(x -> [for (y in ys) for (z in ys) x + y + z]).map(a -> a.length));
		show("map_cb_vals", xs.map(x -> [for (y in ys) for (z in ys) x + y + z])[1]);
		show("switch0", pick(0, xs, ys));
		show("switch1", pick(1, xs, ys));
		show("try_ok", tryIt(xs, ys));
		show("try_throw", tryIt(xs, [1, 0]));
		var nested = [for (x in xs) [for (y in ys) for (z in ys) x + y + z].length];
		show("comp_in_comp", nested);
		var fs = [for (x in xs)() -> [for (y in ys) x + y]];
		show("closures_from_comp", fs[2]());
	}
}
