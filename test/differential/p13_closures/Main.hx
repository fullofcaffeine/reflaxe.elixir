// Differential fixture p13_closures, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p13_closures
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		// statement loops whose bodies hold closures
		var out:Array<Int> = [];
		for (x in xs) {
			var doubled = ys.map(y -> y * x);
			for (d in doubled)
				out.push(d);
		}
		show("map_then_push", out);
		var out2:Array<Int> = [];
		for (x in xs)
			out2 = out2.concat(ys.filter(y -> y > x * 5));
		show("concat_filter", out2);
		var sums:Array<Int> = [];
		for (x in xs) {
			var s = 0;
			Lambda.iter(ys, y -> s += y);
			sums.push(s + x);
		}
		show("iter_capture", sums);
		var fns:Array<Int->Int> = [];
		for (x in xs)
			fns.push(y -> x + y);
		show("fns", fns.map(f -> f(100)));
		var nested:Array<Array<Int>> = [];
		for (x in xs)
			nested.push(ys.map(y -> {
				var acc = [];
				for (z in xs)
					acc.push(z * y);
				acc.length + x;
			}));
		show("closure_loop_in_loop", nested.map(a -> a.join("/")));
		var flat:Array<Int> = [];
		for (a in xs.map(x -> [for (y in ys) x * y]))
			flat = flat.concat(a);
		show("flatmap_comp", flat);
		var folded = Lambda.fold(xs, (x, acc:Array<Int>) -> acc.concat([for (y in ys) x + y]), []);
		show("fold_comp", folded);
		var res:Array<String> = [];
		for (x in xs) {
			var inner = function() {
				var r:Array<String> = [];
				for (y in ys)
					r.push(x + "-" + y);
				return r;
			};
			for (s in inner())
				res.push(s);
		}
		show("inner_fn_loop", res);
	}
}
