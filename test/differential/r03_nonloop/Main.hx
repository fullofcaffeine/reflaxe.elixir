// Differential fixture r03_nonloop, from the PR #87 review probes (user g next to non-loop temps: switch subjects, null coalescing).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r03_nonloop
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function side(x:Int):Int
		return x + 1;

	static function switchTemp(xs:Array<Int>):Int {
		var g = xs.length;
		var r = switch (side(xs[0]) + g) {
			case 1: 10;
			case v if (v > 5): v + g;
			default: g;
		}
		return r + g;
	}

	static function switchTempMut(xs:Array<Int>):Int {
		var g = xs.length;
		g += 1;
		var r = switch (side(g)) {
			case 1: 10;
			case v: v + g;
		}
		g *= 2;
		return r + g;
	}

	static function compAcc(xs:Array<Int>):String {
		var g = [1];
		var c = [for (x in xs) x * 2];
		g.push(c.length);
		return g.join(",") + "|" + c.join(",");
	}

	static function compReadsG(xs:Array<Int>):String {
		var g = [1, 2];
		var c = [for (x in xs) x + g.length];
		g.push(c[0]);
		return g.join(",") + "|" + c.join(",");
	}

	static function compG1(xs:Array<Int>):String {
		var g1 = 10;
		var c = [for (x in xs) x * g1];
		g1 += c.length;
		return g1 + "|" + c.join(",");
	}

	static function compIntoG(xs:Array<Int>):String {
		var g = [for (x in xs) if (x > 1) x];
		g.push(0);
		var g1 = [for (x in g) x + 1];
		return g.join(",") + "|" + g1.join(",");
	}

	static function ifValue(c:Bool):Int {
		var g = 2;
		if (c)
			g = 7;
		return g * 3;
	}

	static function literalG():Int {
		var g = 128;
		var h = g << 8;
		g = 1;
		return g + h;
	}

	static function ternary(c:Bool):String {
		var g = c ? "a" : "b";
		var g1 = g + g;
		return g1;
	}

	static function nullCoal(a:Null<Int>):Int {
		var g = a ?? 5;
		var g1 = g;
		g += 1;
		return g + g1;
	}

	static function main() {
		run("switchTemp", () -> switchTemp([7, 8]));
		run("switchTempMut", () -> switchTempMut([7, 8]));
		run("compAcc", () -> compAcc([1, 2, 3]));
		run("compReadsG", () -> compReadsG([1, 2, 3]));
		run("compG1", () -> compG1([1, 2, 3]));
		run("compIntoG", () -> compIntoG([1, 2, 3]));
		run("ifValue1", () -> ifValue(true));
		run("ifValue2", () -> ifValue(false));
		run("literalG", () -> literalG());
		run("ternary", () -> ternary(true));
		run("nullCoal1", () -> nullCoal(null));
		run("nullCoal2", () -> nullCoal(3));
	}
}
