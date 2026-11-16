// Differential fixture q07_iters, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q07_iters
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function arrIterShared(xs:Array<Int>, ys:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		var it = xs.iterator();
		for (y in ys) {
			if (it.hasNext())
				g.push(it.next() * 10 + y);
		}
		while (it.hasNext())
			g.push(it.next());
		return g;
	}

	static function kvIterCount(m:Map<String, Int>, ys:Array<Int>):Array<Int> {
		var n = 0;
		var rest = 0;
		var it = m.keyValueIterator();
		for (y in ys) {
			if (it.hasNext()) {
				it.next();
				n++;
			}
		}
		while (it.hasNext()) {
			it.next();
			rest++;
		}
		return [n, rest];
	}

	static function kvTwice(m:Map<String, Int>):Array<Int> {
		var g:Array<Int> = [];
		for (k => v in m)
			g.push(v);
		for (k => v in m)
			g.push(v + 10);
		g.sort(Reflect.compare);
		return g;
	}

	static function kvInWhile(m:Map<String, Int>):Array<Int> {
		var g:Array<Int> = [];
		var i = 0;
		while (i < 2) {
			for (k => v in m)
				g.push(v + i * 10);
			i++;
		}
		for (k => v in m)
			g.push(v + 100);
		g.sort(Reflect.compare);
		return g;
	}

	static function main() {
		var m = ["a" => 1, "b" => 2, "c" => 3];
		show("arrIterShared", arrIterShared([1, 2, 3, 4], [5, 6]));
		show("kvIterCount", kvIterCount(m, [1, 2]));
		show("kvTwice", kvTwice(m));
		show("kvInWhile", kvInWhile(m));
	}
}
