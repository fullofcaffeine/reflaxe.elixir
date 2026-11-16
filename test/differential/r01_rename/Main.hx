// Differential fixture r01_rename, from the PR #87 review probes (local_g renames: name clashes with other locals and arguments).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r01_rename
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	// program local already named like the rename target (camelCase -> local_g)
	static function camelClash(n:Int):String {
		var localG = 100;
		var g:Array<Int> = [];
		for (i in 0...n)
			g.push(i);
		localG += g.length;
		return g.join(",") + "|" + localG;
	}

	static function snakeClash(n:Int):String {
		var local_g = 7;
		var g:Array<Int> = [];
		for (i in 0...n)
			g.push(i + local_g);
		local_g++;
		return g.join(",") + "|" + local_g;
	}

	static function clashDeclaredAfter(n:Int):String {
		var g:Array<Int> = [];
		for (i in 0...n)
			g.push(i);
		var localG = g.length * 2;
		var local_g_2 = 5;
		return g.join(",") + "|" + localG + "|" + local_g_2;
	}

	static function unusedArgClash(localG:Int, n:Int):String {
		var g:Array<Int> = [];
		for (i in 0...n)
			g.push(i);
		return g.join(",");
	}

	static function usedArgClash(localG:Int, n:Int):String {
		var g:Array<Int> = [];
		for (i in 0...n)
			g.push(i + localG);
		return g.join(",") + "|" + localG;
	}

	static function twoScopes(n:Int):String {
		var g = 1;
		var out = [];
		{
			var g = 2;
			for (i in 0...n)
				g += i;
			out.push(g);
		}
		out.push(g);
		for (i in 0...n)
			g += 10;
		out.push(g);
		return out.join(",");
	}

	static function g1AndG(n:Int):String {
		var g = 0;
		var g1 = 100;
		var g2 = 1000;
		for (i in 0...n) {
			g += i;
			g1 += i;
			g2 += i;
		}
		return g + "," + g1 + "," + g2;
	}

	static function reassignThenFor(n:Int):String {
		var g = 0;
		g = 5;
		for (i in 0...n)
			g += i;
		var h = g;
		g = 1;
		return g + "," + h;
	}

	static function emptyLoop():String {
		var g = 3;
		for (i in 0...0)
			g += 100;
		var k = 0;
		while (k < 0) {
			g = 99;
			k++;
		}
		return "" + g;
	}

	static function main() {
		run("camelClash", () -> camelClash(3));
		run("snakeClash", () -> snakeClash(3));
		run("clashDeclaredAfter", () -> clashDeclaredAfter(3));
		run("unusedArgClash", () -> unusedArgClash(9, 3));
		run("usedArgClash", () -> usedArgClash(9, 3));
		run("twoScopes", () -> twoScopes(3));
		run("g1AndG", () -> g1AndG(3));
		run("reassignThenFor", () -> reassignThenFor(3));
		run("emptyLoop", () -> emptyLoop());
	}
}
