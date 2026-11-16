// Differential fixture q11_range_g9, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q11_range_g9
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function rangeFor(n:Int):Array<Int> {
		var g9:Array<Int> = [];
		for (i in 0...n) {
			var j = 0;
			while (j < 2) {
				g9.push(i * 10 + j);
				j++;
			}
		}
		for (i in 0...n)
			g9.push(i + 100);
		var t = 0;
		while (t < 2) {
			g9.push(t + 200);
			t++;
		}
		return g9;
	}

	static function rangeInWhile(n:Int):Array<Int> {
		var g9:Array<Int> = [];
		var a = 0;
		while (a < 2) {
			for (i in 0...n)
				g9.push(a * 10 + i);
			a++;
		}
		for (i in 0...n) {
			var j = 0;
			while (j < 1) {
				g9.push(i + 100);
				j++;
			}
		}
		return g9;
	}

	static function rangeBreak(n:Int):Array<Int> {
		var g9:Array<Int> = [];
		for (i in 0...n) {
			if (i > 1)
				break;
			var j = 0;
			while (j < 2) {
				g9.push(i * 10 + j);
				j++;
			}
		}
		var t = 0;
		while (t < 2) {
			g9.push(t + 200);
			t++;
		}
		return g9;
	}

	static function rangeRet(n:Int, lim:Int):Array<Int> {
		var g9:Array<Int> = [];
		for (i in 0...n) {
			var j = 0;
			while (j < 2) {
				if (i * 10 + j > lim)
					return g9;
				g9.push(i * 10 + j);
				j++;
			}
		}
		var t = 0;
		while (t < 2) {
			g9.push(t + 200);
			t++;
		}
		return g9;
	}

	static function kvRangeWhile(m:Map<String, Int>, n:Int):Array<Int> {
		var g9:Array<Int> = [];
		for (k => v in m) {
			for (i in 0...n) {
				var j = 0;
				while (j < 2) {
					g9.push(v * 100 + i * 10 + j);
					j++;
				}
			}
		}
		var t = 0;
		while (t < 2) {
			g9.push(t);
			t++;
		}
		for (k in m.keys())
			g9.push(m.get(k) + 1000);
		g9.sort(Reflect.compare);
		return g9;
	}

	static function main() {
		var m = ["a" => 1, "b" => 2];
		show("rangeFor", rangeFor(2));
		show("rangeFor0", rangeFor(0));
		show("rangeInWhile", rangeInWhile(2));
		show("rangeBreak", rangeBreak(4));
		show("rangeRet_early", rangeRet(3, 10));
		show("rangeRet_full", rangeRet(2, 99));
		show("kvRangeWhile", kvRangeWhile(m, 2));
	}
}
