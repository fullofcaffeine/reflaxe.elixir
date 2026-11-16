// Differential fixture r09_more, from the PR #87 review probes (user g next to comprehension and switch temps).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r09_more
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function elseAliasG(c:Bool, x:Int):Int {
		var g = x * 2;
		var h = 0;
		if (c) {
			g = 1;
			h = 2;
		} else {
			h = g;
		}
		return g + h;
	}

	static function elseAliasQ(c:Bool, x:Int):Int {
		var q = x * 2;
		var h = 0;
		if (c) {
			q = 1;
			h = 2;
		} else {
			h = q;
		}
		return q + h;
	}

	static function objField(n:Int):String {
		var g = 0;
		for (i in 0...n)
			g += i;
		var o = {g: g, n: n};
		return o.g + "/" + o.n;
	}

	static function compWhile():String {
		var g = 10;
		var i = 0;
		var c = [while (i < 3) i++];
		g += c.length;
		return g + "|" + c.join(",");
	}

	static function mapComp(xs:Array<Int>):String {
		var g = 2;
		var m = [for (x in xs) x => x * g];
		g += m.get(2);
		return "" + g;
	}

	static function counterAndSwitch(xs:Array<Int>):String {
		var g = 0;
		var label = switch (xs.length % 3) {
			case 0: "a";
			case 1: "b";
			default: "c";
		}
		g++;
		return label + g;
	}

	static function flagAndSwitch(name:String, c:Bool):String {
		var g = 0;
		if (c)
			g = 1;
		var s = switch (name.charAt(0)) {
			case "x": "ex";
			case other: other + "!";
		}
		return s + g;
	}

	static function g1AndSwitch(a:Int, b:Int):Int {
		var g1 = 100;
		var r = switch [a + 1, b + 1] {
			case [1, _]: 0;
			case [p, q]: p * q;
		}
		return r + g1;
	}

	static function switchThenLoop(xs:Array<Int>):Int {
		var g = 7;
		var r = switch (xs.length + 1) {
			case 1: 0;
			case v: v;
		}
		for (x in xs)
			r += x;
		return r + g;
	}

	static function main() {
		run("elseAliasG1", () -> elseAliasG(true, 5));
		run("elseAliasG2", () -> elseAliasG(false, 5));
		run("elseAliasQ1", () -> elseAliasQ(true, 5));
		run("elseAliasQ2", () -> elseAliasQ(false, 5));
		run("objField", () -> objField(4));
		run("compWhile", () -> compWhile());
		run("mapComp", () -> mapComp([1, 2, 3]));
		run("counterAndSwitch", () -> counterAndSwitch([1, 2]));
		run("flagAndSwitch1", () -> flagAndSwitch("abc", true));
		run("flagAndSwitch2", () -> flagAndSwitch("xyz", false));
		run("g1AndSwitch", () -> g1AndSwitch(2, 3));
		run("switchThenLoop", () -> switchThenLoop([1, 2]));
	}
}
