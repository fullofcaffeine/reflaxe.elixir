// Differential fixture q02_exits, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q02_exits
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function brk(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			if (x > 2)
				break;
			var j = 0;
			while (j < 2) {
				g.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		return g;
	}

	static function cont(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			if (x == 2)
				continue;
			var j = 0;
			while (j < 2) {
				g.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		return g;
	}

	static function innerBreak(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (true) {
				if (j >= 2)
					break;
				g.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		return g;
	}

	static function ret(xs:Array<Int>, lim:Int):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				if (x * 10 + j > lim)
					return g;
				g.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		return g;
	}

	static function retWhile(lim:Int):Array<Int> {
		var g:Array<Int> = [];
		var a = 0;
		while (a < 3) {
			if (a > lim)
				return g;
			g.push(a);
			a++;
		}
		var i = 0;
		while (i < 2) {
			g.push(i + 10);
			i++;
		}
		return g;
	}

	static function thr(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		try {
			for (x in xs) {
				var j = 0;
				while (j < 2) {
					if (x == 3)
						throw "boom";
					g.push(x * 10 + j);
					j++;
				}
			}
		} catch (e:String) {
			var q = 0;
			while (q < 1) {
				g.push(-1);
				q++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		return g;
	}

	static function main() {
		show("brk", brk([1, 2, 3, 4]));
		show("brk_none", brk([1, 2]));
		show("cont", cont([1, 2, 3]));
		show("innerBreak", innerBreak([1, 2]));
		show("ret_early", ret([1, 2, 3], 20));
		show("ret_full", ret([1, 2], 99));
		show("retWhile_early", retWhile(1));
		show("retWhile_full", retWhile(9));
		show("thr_ok", thr([1, 2]));
		show("thr_boom", thr([1, 3]));
	}
}
