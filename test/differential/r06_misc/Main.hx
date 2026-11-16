// Differential fixture r06_misc, from the PR #87 review probes (user g in constructors, static initializers, inline functions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r06_misc
class Counter {
	public var total:Int;

	public function new(n:Int) {
		var g = 0;
		for (i in 0...n)
			g += i;
		total = g;
	}

	public function grow(n:Int):Int {
		var g = total;
		var k = 0;
		while (k < n) {
			g += k;
			k++;
		}
		total = g;
		return total;
	}
}

class Main {
	static var table:Array<Int> = {
		var g = [];
		for (i in 0...3)
			g.push(i * i);
		g;
	};
	static var sum:Int = {
		var g = 1;
		g = 4;
		var i = 0;
		while (i < 3) {
			g += i;
			i++;
		}
		g;
	};

	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static inline function inlSum(xs:Array<Int>):Int {
		var g = 0;
		for (x in xs)
			g += x;
		return g;
	}

	static function useInline(xs:Array<Int>):Int {
		var g = 100;
		var a = inlSum(xs);
		g += a;
		return g + inlSum([1, 2]);
	}

	static function argG(g:Int, n:Int):Int {
		for (i in 0...n)
			g += i;
		return g;
	}

	static function argG1(g1:Int, n:Int):String {
		var acc = [];
		for (i in 0...n)
			acc.push(i + g1);
		return acc.join(",") + "|" + g1;
	}

	static function catchG(n:Int):String {
		var out = [];
		for (i in 0...n) {
			try {
				if (i == 1)
					throw "e" + i;
				out.push("ok" + i);
			} catch (g:String) {
				out.push(g);
			}
		}
		return out.join(",");
	}

	static function doWhile():Int {
		var g = 0;
		do {
			g += 2;
		} while (g < 7);
		return g;
	}

	static function mapIter(m:Map<String, Int>):String {
		var g = [];
		for (k => v in m)
			g.push(k + v);
		g.sort((a, b) -> a < b ? -1 : 1);
		var g1 = 0;
		for (v in m)
			g1 += v;
		return g.join(",") + "|" + g1;
	}

	static function stringG(xs:Array<String>):String {
		var g = "";
		for (x in xs)
			g += x;
		var g2 = g.length;
		for (i in 0...2)
			g2 += i;
		return g + g2;
	}

	static function breakCont(xs:Array<Int>):Int {
		var g = 0;
		for (x in xs) {
			if (x == 2)
				continue;
			if (x == 5)
				break;
			g += x;
		}
		return g;
	}

	static function nestedLoops(n:Int):Int {
		var g = 0;
		for (i in 0...n)
			for (j in 0...i)
				g += j;
		return g;
	}

	static function g9g(n:Int):String {
		var g9:Array<Int> = [];
		var g = 0;
		for (i in 0...n) {
			g9.push(i);
			g += i;
		}
		return g9.join(",") + "|" + g;
	}

	static function main() {
		run("table", () -> table.join(","));
		run("sum", () -> sum);
		run("ctor", () -> new Counter(4).total);
		run("grow", () -> new Counter(4).grow(3));
		run("useInline", () -> useInline([1, 2, 3]));
		run("argG1", () -> argG1(5, 3));
		run("catchG", () -> catchG(3));
		run("doWhile", () -> doWhile());
		run("mapIter", () -> mapIter(["a" => 1, "b" => 2]));
		run("stringG", () -> stringG(["x", "y"]));
		run("breakCont", () -> breakCont([1, 2, 3, 5, 9]));
		run("nestedLoops", () -> nestedLoops(4));
		run("g9g", () -> g9g(3));
	}
}
