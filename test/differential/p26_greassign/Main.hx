// Differential fixture p26_greassign, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p26_greassign
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function reassigned(n:Int):Int {
		var g = 0;
		g = 5;
		var i = 0;
		while (i < n) {
			g++;
			i++;
		}
		return g;
	}

	static function pushedBefore():Array<Int> {
		var g = [1];
		g.push(2);
		var i = 0;
		while (i < 2) {
			g.push(i * 10);
			i++;
		}
		return g;
	}

	static function twoWhiles():Array<Int> {
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
		return g;
	}

	static function main() {
		show("reassigned", [reassigned(3)]);
		show("pushedBefore", pushedBefore());
		show("twoWhiles", twoWhiles());
	}
}
