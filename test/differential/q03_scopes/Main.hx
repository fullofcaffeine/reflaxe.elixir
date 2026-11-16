// Differential fixture q03_scopes, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q03_scopes
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function sw(k:Int, xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		switch (k) {
			case 0:
				var i = 0;
				while (i < 2) {
					g.push(i);
					i++;
				}
			case 1:
				for (x in xs) {
					var j = 0;
					while (j < 2) {
						g.push(x * 10 + j);
						j++;
					}
				}
			default:
		}
		var t = 0;
		while (t < 2) {
			g.push(100 + t);
			t++;
		}
		return g;
	}

	static function ifElse(c:Bool, xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		if (c) {
			for (x in xs) {
				var j = 0;
				while (j < 2) {
					g.push(x * 10 + j);
					j++;
				}
			}
		} else {
			var i = 0;
			while (i < 2) {
				g.push(i);
				i++;
			}
		}
		var t = 0;
		while (t < 2) {
			g.push(100 + t);
			t++;
		}
		return g;
	}

	static function ifOnly(c:Bool, xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		if (c) {
			for (x in xs) {
				var j = 0;
				while (j < 2) {
					g.push(x * 10 + j);
					j++;
				}
			}
		}
		for (x in xs)
			g.push(x);
		var t = 0;
		while (t < 2) {
			g.push(100 + t);
			t++;
		}
		return g;
	}

	static function tryBlock(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		try {
			for (x in xs) {
				var j = 0;
				while (j < 2) {
					g.push(x * 10 + j);
					j++;
				}
			}
		} catch (e:Dynamic) {
			g.push(-1);
		}
		var t = 0;
		while (t < 2) {
			g.push(100 + t);
			t++;
		}
		return g;
	}

	static function closure(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		var f = function() {
			var j = 0;
			while (j < 2) {
				g.push(j);
				j++;
			}
		};
		f();
		var t = 0;
		while (t < 2) {
			g.push(100 + t);
			t++;
		}
		return g;
	}

	static function closureInFor(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs) {
			var f = function(y:Int) {
				var j = 0;
				while (j < 2) {
					g.push(y * 10 + j);
					j++;
				}
			};
			f(x);
			g.push(x);
		}
		var t = 0;
		while (t < 2) {
			g.push(100 + t);
			t++;
		}
		return g;
	}

	static function lambdaComp(xs:Array<Int>, im:Map<Int, String>):Array<Int> {
		return xs.map(x -> {
			var r = [for (i in 0...2) for (k in im.keys()) x * 100 + i * 10 + k];
			r.length;
		});
	}

	static function compInForBody(xs:Array<Int>, im:Map<Int, String>):Array<Int> {
		var out:Array<Int> = [];
		for (x in xs) {
			var r = [for (i in 0...2) for (k in im.keys()) x * 100 + i * 10 + k];
			r.sort(Reflect.compare);
			for (v in r)
				out.push(v);
		}
		return out;
	}

	static function main() {
		var xs = [1, 2];
		var im = [1 => "one", 2 => "two"];
		show("sw0", sw(0, xs));
		show("sw1", sw(1, xs));
		show("sw2", sw(2, xs));
		show("if_t", ifElse(true, xs));
		show("if_f", ifElse(false, xs));
		show("ifOnly_t", ifOnly(true, xs));
		show("ifOnly_f", ifOnly(false, xs));
		show("try", tryBlock(xs));
		show("closure", closure(xs));
		show("closureInFor", closureInFor(xs));
		show("lambdaComp", lambdaComp(xs, im));
		show("compInForBody", compInForBody(xs, im));
	}
}
