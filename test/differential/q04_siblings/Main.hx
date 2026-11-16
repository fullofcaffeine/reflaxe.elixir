// Differential fixture q04_siblings, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q04_siblings
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function twoFor(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs)
			g.push(x);
		for (x in xs)
			g.push(x + 10);
		return g;
	}

	static function forThenWhile(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs)
			g.push(x);
		var i = 0;
		while (i < 2) {
			g.push(i + 10);
			i++;
		}
		return g;
	}

	static function whileThenFor(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		var i = 0;
		while (i < 2) {
			g.push(i + 10);
			i++;
		}
		for (x in xs)
			g.push(x);
		return g;
	}

	static function threeWhiles():Array<Int> {
		var g:Array<Int> = [];
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		var j = 0;
		while (j < 2) {
			g.push(j + 10);
			j++;
		}
		var k = 0;
		while (k < 2) {
			g.push(k + 20);
			k++;
		}
		return g;
	}

	static function discarded(xs:Array<Int>):Int {
		var g:Array<Int> = [];
		var n = 0;
		for (x in xs) {
			g.push(x);
			n++;
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
			n++;
		}
		return n;
	}

	static function discardedFirst(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		var h:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				g.push(x);
				h.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			h.push(i);
			i++;
		}
		return h;
	}

	static function voidTail(xs:Array<Int>):Void {
		var g:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				g.push(j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
	}

	static function counterG(xs:Array<Int>):Int {
		var g = 0;
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				g += x;
				j++;
			}
		}
		var i = 0;
		while (i < 3) {
			g++;
			i++;
		}
		return g;
	}

	static function g1Name(xs:Array<Int>):Array<Int> {
		var g1:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				g1.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g1.push(i);
			i++;
		}
		for (x in xs)
			g1.push(-x);
		return g1;
	}

	static function twoLocals(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		var g1:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				g.push(x * 10 + j);
				j++;
			}
			g1.push(x);
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			g1.push(i + 50);
			i++;
		}
		return g.concat(g1);
	}

	static function main() {
		var xs = [1, 2];
		show("twoFor", twoFor(xs));
		show("forThenWhile", forThenWhile(xs));
		show("whileThenFor", whileThenFor(xs));
		show("threeWhiles", threeWhiles());
		show("discarded", [discarded(xs)]);
		show("discardedFirst", discardedFirst(xs));
		voidTail(xs);
		show("counterG", [counterG(xs)]);
		show("g1Name", g1Name(xs));
		show("twoLocals", twoLocals(xs));
		show("empty_twoLocals", twoLocals([]));
		show("empty_g1Name", g1Name([]));
	}
}
