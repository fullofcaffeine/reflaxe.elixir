// Differential fixture p28_tuplebind, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p28_tuplebind
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function ifPair(x:Int):Int {
		var g = 1;
		var h = 0;
		if (x > 1) {
			g = 2;
			h = 3;
		} else {
			g = 4;
			h = 5;
		}
		return g;
	}

	static function ifPairNamed(x:Int):Int {
		var r = x * 2;
		var h = 0;
		if (x > 1) {
			r = x + 2;
			h = 3;
		} else {
			r = x + 4;
			h = 5;
		}
		return r;
	}

	static function switchPair(x:Int):Int {
		var g = x * 10;
		var h = 0;
		switch (x) {
			case 1:
				g = 7;
				h = 1;
			case 2:
				g = 8;
				h = 2;
			default:
		}
		return g;
	}

	static function switchPairNamed(x:Int):Int {
		var res = x * 10;
		var h = 0;
		switch (x) {
			case 1:
				res = 7;
				h = 1;
			case 2:
				res = 8;
				h = 2;
			default:
		}
		return res + 0 * h;
	}

	static function main() {
		show("ifPair", [ifPair(0), ifPair(5)]);
		show("ifPairNamed", [ifPairNamed(0), ifPairNamed(5)]);
		show("switchPair", [switchPair(1), switchPair(2), switchPair(3)]);
		show("switchPairNamed", [switchPairNamed(1), switchPairNamed(3)]);
	}
}
