// Differential fixture p19_iife, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p19_iife
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function id(v:Int):Int
		return v;

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var out:Array<Int> = [];
		for (x in xs)
			out.push({var t:Array<Int> = []; for (y in ys) t.push(y * x); t.length + x;});
		show("block_arg", out);
		var out2:Array<Int> = [];
		var side:Array<Int> = [];
		for (x in xs)
			out2.push(id(if (x > 1) {
				for (y in ys)
					side.push(y + x);
				side.length;
			} else 0));
		show("iife_side_out", out2);
		show("iife_side", side);
		var lens = [
			for (x in xs)
				id({var t:Array<Int> = []; for (y in ys) t.push(y); t.length * x;})
		];
		show("comp_block_arg", lens);
	}
}
