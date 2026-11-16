// Differential fixture p08_params, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p08_params
class Holder {
	public var items:Array<Int> = [];

	public function new() {}

	public function fill(items:Array<Int>, xs:Array<Int>):Array<Int> {
		for (x in xs)
			for (y in xs)
				items.push(x * y);
		this.items = items;
		return items;
	}
}

class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function sumInto(acc:Int, xs:Array<Int>):Int {
		for (x in xs)
			for (y in xs)
				acc += x * y;
		return acc;
	}

	static function addAll(out:Array<Int>, xs:Array<Int>):Array<Int> {
		for (x in xs)
			out.push(x);
		return out;
	}

	static function main() {
		show("param_int", [sumInto(1, [1, 2])]);
		show("param_arr", addAll([0], [1, 2]));
		show("field_param", new Holder().fill([9], [1, 2]));
		var end = 0;
		for (x in [1, 2, 3])
			end += x;
		show("reserved", [end]);
		var fn = [];
		for (x in [1, 2])
			for (y in [3])
				fn.push(x * y);
		show("reserved_arr", fn);
	}
}
