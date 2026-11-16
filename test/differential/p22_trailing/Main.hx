// Differential fixture p22_trailing, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p22_trailing
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function countUp(n:Int):Int {
		var g = 0;
		var i = 0;
		while (i < n) {
			g += i;
			i++;
		}
		return g;
	}

	static function games(n:Int):Int {
		var games = 1;
		var i = 0;
		while (i < n) {
			games *= 2;
			i++;
		}
		return games;
	}

	static function pick(c:Bool):Int {
		var r = 1;
		if (c)
			r = 2;
		return r;
	}

	static function viaSwitch(k:Int):String {
		var s = "x";
		switch (k) {
			case 1:
				s = "one";
			default:
		}
		return s;
	}

	static function tryRet(k:Int):Int {
		var v = 0;
		try {
			if (k == 0)
				throw "z";
			v = 10 / k > 1 ? 5 : 6;
		} catch (e:String) {
			v = -1;
		}
		return v;
	}

	static function tuple(xs:Array<Int>):Int {
		var a = 0;
		var b = 0;
		for (x in xs) {
			a += x;
			b += x * 2;
		}
		return a + b;
	}

	static function lastOfTwo(xs:Array<Int>):Array<Int> {
		var g = [0];
		for (x in xs)
			g.push(x);
		return g;
	}

	static function thisLike():Array<Int> {
		var this1 = [1];
		this1.push(2);
		return this1;
	}

	static function keysThenLen(m:Map<String, Int>):Int {
		var g = [for (k in m.keys()) k];
		return g.length;
	}

	static function whileArr(n:Int):Array<Int> {
		var g1 = [];
		var i = 0;
		while (i < n) {
			g1.push(i);
			i++;
		}
		return g1;
	}

	static function main() {
		show("countUp", [countUp(4)]);
		show("games", [games(3)]);
		show("pick", [pick(true), pick(false)]);
		show("viaSwitch", [viaSwitch(1), viaSwitch(2)]);
		show("tryRet", [tryRet(0), tryRet(5), tryRet(20)]);
		show("tuple", [tuple([1, 2, 3])]);
		show("lastOfTwo", lastOfTwo([5, 6]));
		show("thisLike", thisLike());
		show("keysThenLen", [keysThenLen(["a" => 1, "b" => 2])]);
		show("whileArr", whileArr(3));
	}
}
