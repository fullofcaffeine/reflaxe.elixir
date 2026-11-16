// Differential fixture r11_iter_names, from the PR #90 review probes (loop variables named like temps over an iterator: Haxe names the iterator after the loop variable).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r11_iter_names
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function keysSum(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys())
			acc += g;
		return acc;
	}

	static function valuesSum(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m)
			acc += g;
		return acc;
	}

	static function arrayIterSum(xs:Array<Int>):Int {
		var acc = 0;
		for (g in xs.iterator())
			acc += g;
		return acc;
	}

	static function keysSumG1(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g1 in m.keys())
			acc += g1;
		return acc;
	}

	static function keysSumUnder(m:Map<Int, Int>):Int {
		var acc = 0;
		for (_g in m.keys())
			acc += _g;
		return acc;
	}

	static function keysCollect(m:Map<Int, Int>):String {
		var out = [];
		for (g in m.keys())
			out.push(g * 2);
		out.sort((a, b) -> a - b);
		return out.join(",");
	}

	static function keysComp(m:Map<Int, Int>):String {
		var out = [for (g in m.keys()) g * 2];
		out.sort((a, b) -> a - b);
		return out.join(",");
	}

	static function keysArg(g:Int, m:Map<Int, Int>):Int {
		var acc = 0;
		for (k in m.keys())
			acc += k * g;
		return acc;
	}

	static function keysLocal(m:Map<Int, Int>):Int {
		var g = 10;
		var acc = 0;
		for (k in m.keys())
			acc += k * g;
		return acc + g;
	}

	static function strIter(s:String):Int {
		var acc = 0;
		for (g in new haxe.iterators.StringIterator(s))
			acc += g;
		return acc;
	}

	static function listIter():Int {
		var l = new List<Int>();
		l.add(1);
		l.add(2);
		l.add(3);
		var acc = 0;
		for (g in l)
			acc += g;
		return acc;
	}

	static function twoIters(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys())
			acc += g;
		for (g in m.keys())
			acc += g * 10;
		return acc;
	}

	static function main() {
		run("keysSum", () -> keysSum([1 => 10, 2 => 20, 3 => 30]));
		run("valuesSum", () -> valuesSum([1 => 10, 2 => 20, 3 => 30]));
		run("arrayIterSum", () -> arrayIterSum([1, 2, 3]));
		run("keysSumG1", () -> keysSumG1([1 => 10, 2 => 20, 3 => 30]));
		run("keysSumUnder", () -> keysSumUnder([1 => 10, 2 => 20, 3 => 30]));
		run("keysCollect", () -> keysCollect([1 => 10, 2 => 20, 3 => 30]));
		run("keysComp", () -> keysComp([1 => 10, 2 => 20, 3 => 30]));
		run("keysArg", () -> keysArg(2, [1 => 10, 2 => 20, 3 => 30]));
		run("keysLocal", () -> keysLocal([1 => 10, 2 => 20, 3 => 30]));
		run("strIter", () -> strIter("ab"));
		run("listIter", () -> listIter());
		run("twoIters", () -> twoIters([1 => 10, 2 => 20, 3 => 30]));
	}
}
