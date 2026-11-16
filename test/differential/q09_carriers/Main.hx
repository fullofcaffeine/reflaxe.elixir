// Differential fixture q09_carriers, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q09_carriers
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function retInIf(c:Bool, lim:Int):Array<Int> {
		var g:Array<Int> = [];
		if (c) {
			var a = 0;
			while (a < 3) {
				if (a > lim)
					return g;
				g.push(a);
				a++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i + 10);
			i++;
		}
		return g;
	}

	static function retFor(xs:Array<Int>, lim:Int):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			if (x > lim)
				return g;
			g.push(x);
		}
		for (x in xs)
			g.push(x + 10);
		var i = 0;
		while (i < 1) {
			g.push(99);
			i++;
		}
		return g;
	}

	static function retNested(xs:Array<Int>, lim:Int):Array<Int> {
		var g:Array<Int> = [];
		var a = 0;
		while (a < 2) {
			for (x in xs) {
				if (x * (a + 1) > lim)
					return g;
				g.push(x * (a + 1));
			}
			a++;
		}
		var i = 0;
		while (i < 2) {
			g.push(i + 100);
			i++;
		}
		return g;
	}

	static function doWhile():Array<Int> {
		var g:Array<Int> = [];
		var i = 0;
		do {
			g.push(i);
			i++;
		} while (i < 2);
		var j = 0;
		while (j < 2) {
			g.push(j + 10);
			j++;
		}
		return g;
	}

	static function breakComp(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			if (x > 2)
				break;
			g.push(x);
		}
		var j = 0;
		while (j < 2) {
			g.push(j + 10);
			j++;
		}
		for (x in xs) {
			if (x == 1)
				continue;
			g.push(x + 20);
		}
		return g;
	}

	static function rangeFor(n:Int):Array<Int> {
		var g:Array<Int> = [];
		for (i in 0...n) {
			var j = 0;
			while (j < 2) {
				g.push(i * 10 + j);
				j++;
			}
		}
		for (i in 0...n)
			g.push(i + 100);
		var t = 0;
		while (t < 2) {
			g.push(t + 200);
			t++;
		}
		return g;
	}

	static function rangeInWhile(n:Int):Array<Int> {
		var g:Array<Int> = [];
		var a = 0;
		while (a < 2) {
			for (i in 0...n)
				g.push(a * 10 + i);
			a++;
		}
		for (i in 0...n) {
			var j = 0;
			while (j < 1) {
				g.push(i + 100);
				j++;
			}
		}
		return g;
	}

	static function main() {
		show("retInIf_t_early", retInIf(true, 0));
		show("retInIf_t_full", retInIf(true, 9));
		show("retInIf_f", retInIf(false, 9));
		show("retFor_early", retFor([1, 2, 3], 1));
		show("retFor_full", retFor([1, 2], 9));
		show("retNested_early", retNested([1, 2], 3));
		show("retNested_full", retNested([1, 2], 99));
		show("doWhile", doWhile());
		show("breakComp", breakComp([1, 2, 3]));
		show("rangeFor", rangeFor(2));
		show("rangeFor0", rangeFor(0));
		show("rangeInWhile", rangeInWhile(2));
	}
}
