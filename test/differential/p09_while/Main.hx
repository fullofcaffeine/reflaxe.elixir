// Differential fixture p09_while, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p09_while
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		var out:Array<Int> = [];
		for (x in xs) {
			var i = 0;
			while (i < x) {
				out.push(x * 10 + i);
				i++;
			}
		}
		show("for_while", out);
		var r = [
			for (x in xs) {
				var j = x;
				while (j > 0)
					j--;
				j + x;
			}
		];
		show("comp_while_body", r);
		var acc:Array<Int> = [];
		var k = 0;
		while (k < 2) {
			for (x in xs)
				acc.push(k * 10 + x);
			k++;
		}
		show("while_for", acc);
		var m = ["a" => 1, "b" => 2];
		var keys:Array<String> = [];
		for (x in xs)
			for (key in m.keys())
				if (m.get(key) == x)
					keys.push(key + x);
		keys.sort(Reflect.compare);
		show("stmt_keys", keys);
	}
}
