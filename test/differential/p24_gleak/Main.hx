// Differential fixture p24_gleak, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p24_gleak
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2];
		var g:Array<Int> = [];
		for (x in xs) {
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
		show("g_after_nested", g);
	}
}
