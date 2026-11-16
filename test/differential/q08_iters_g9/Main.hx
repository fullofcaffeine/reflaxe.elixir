// Differential fixture q08_iters_g9, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q08_iters_g9
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function arrIterShared(xs:Array<Int>, ys:Array<Int>):Array<Int> {
		var g9:Array<Int> = [];
		var it = xs.iterator();
		for (y in ys) {
			if (it.hasNext())
				g9.push(it.next() * 10 + y);
		}
		while (it.hasNext())
			g9.push(it.next());
		return g9;
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
		var g9:Array<Int> = [];
		for (k => v in m)
			g9.push(v);
		for (k => v in m)
			g9.push(v + 10);
		g9.sort(Reflect.compare);
		return g9;
	}

	static function kvInWhile(m:Map<String, Int>):Array<Int> {
		var g9:Array<Int> = [];
		var i = 0;
		while (i < 2) {
			for (k => v in m)
				g9.push(v + i * 10);
			i++;
		}
		for (k => v in m)
			g9.push(v + 100);
		g9.sort(Reflect.compare);
		return g9;
	}

	static function main() {
		var m = ["a" => 1, "b" => 2, "c" => 3];
		show("arrIterShared", arrIterShared([1, 2, 3, 4], [5, 6]));
		show("kvIterCount", kvIterCount(m, [1, 2]));
		show("kvTwice", kvTwice(m));
		show("kvInWhile", kvInWhile(m));
	}
}
