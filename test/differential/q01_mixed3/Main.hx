// Differential fixture q01_mixed3, from the PR #83 second-round review probes (loop state after loops, user locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture q01_mixed3
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	// receiver-iterator loop > reduce_while > Enum.reduce, with sibling loops at two levels
	static function kvWhileFor(m:Map<String, Int>, xs:Array<Int>):Array<String> {
		var g:Array<String> = [];
		for (k => v in m) {
			var i = 0;
			while (i < 2) {
				for (x in xs)
					g.push(k + v + "-" + i + "-" + x);
				i++;
			}
			var j = 0;
			while (j < 1) {
				g.push(k + "!");
				j++;
			}
		}
		var t = 0;
		while (t < 2) {
			g.push("t" + t);
			t++;
		}
		for (x in xs)
			g.push("x" + x);
		return g;
	}

	// Enum.reduce > reduce_while > receiver-iterator loop
	static function forWhileKv(m:Map<String, Int>, xs:Array<Int>):Array<String> {
		var g:Array<String> = [];
		for (x in xs) {
			var i = 0;
			while (i < 2) {
				for (k => v in m)
					g.push(k + v + "-" + i + "-" + x);
				i++;
			}
		}
		var t = 0;
		while (t < 2) {
			g.push("t" + t);
			t++;
		}
		return g;
	}

	// reduce_while > Enum.reduce > reduce_while
	static function whileForWhile(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		var a = 0;
		while (a < 2) {
			for (x in xs) {
				var j = 0;
				while (j < 2) {
					g.push(a * 100 + x * 10 + j);
					j++;
				}
			}
			a++;
		}
		var t = 0;
		while (t < 2) {
			g.push(t);
			t++;
		}
		return g;
	}

	// Enum.reduce > Enum.reduce > reduce_while, then reduce sibling, then reduce_while sibling
	static function forForWhile(xs:Array<Int>):Array<Int> {
		var g:Array<Int> = [];
		for (x in xs)
			for (y in xs) {
				var j = 0;
				while (j < 2) {
					g.push(x * 100 + y * 10 + j);
					j++;
				}
			}
		for (x in xs)
			g.push(x);
		var t = 0;
		while (t < 2) {
			g.push(-t);
			t++;
		}
		return g;
	}

	// map keys > reduce_while > Enum.reduce, sibling keys loop after
	static function keysWhileFor(m:Map<String, Int>, xs:Array<Int>):Array<String> {
		var g:Array<String> = [];
		for (k in m.keys()) {
			var i = 0;
			while (i < 2) {
				for (x in xs)
					g.push(k + i + x);
				i++;
			}
		}
		for (k in m.keys())
			g.push(k + "#");
		return g;
	}

	static function main() {
		var m = ["a" => 1, "b" => 2];
		var im = [1 => "one", 2 => "two"];
		var xs = [1, 2];
		show("kvWhileFor", kvWhileFor(m, xs));
		show("forWhileKv", forWhileKv(m, xs));
		show("whileForWhile", whileForWhile(xs));
		show("forForWhile", forForWhile(xs));
		show("keysWhileFor", keysWhileFor(m, xs));
		show("c_kv_r_for", [for (k => v in m) for (i in 0...2) for (x in xs) k + v + i + x]);
		show("c_for_kv_keys", [for (x in xs) for (k => v in m) for (j in im.keys()) k + v + x + j]);
		show("c_r3_keys_for", [for (i in 0...3) for (k in m.keys()) for (x in xs) k + i + x]);
		show("c_keys_for_kv", [for (j in im.keys()) for (x in xs) for (k => v in m) k + v + x + j]);
	}
}
