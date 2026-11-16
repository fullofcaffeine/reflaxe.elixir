// Differential fixture p10_single, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p10_single
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		Sys.println(label + "=" + s.join(","));
	}

	static function main() {
		var xs = [1, 2, 3];
		var m = ["a" => 1, "b" => 2];
		var a = [for (x in xs) x * 2];
		var b = [for (k in m.keys()) k];
		b.sort(Reflect.compare);
		var c = [for (k in m.keys()) m.get(k)];
		c.sort(Reflect.compare);
		var d = [for (i in 0...3) i];
		show("a", a);
		show("b", b);
		show("c", c);
		show("d", d);
		var e = [for (x in xs) if (x > 1) x];
		show("e", e);
		var f = xs.map(x -> x + 1).filter(x -> x > 2);
		show("f", f);
		var sum = 0;
	}
}
