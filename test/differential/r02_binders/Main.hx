// Differential fixture r02_binders, from the PR #87 review probes (match binders named g next to loops).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r02_binders
enum Color {
	RGB(r:Int, g:Int, b:Int);
	Gray(g:Int);
}

enum Res {
	Ok(v:Int);
	Error(g:String);
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function binderAfterLoop(c:Color, n:Int):Int {
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return switch (c) {
			case RGB(r, g, b): r + g * 10 + b * 100 + acc;
			case Gray(g): g + acc;
		}
	}

	static function binderInLoop(cs:Array<Color>):Int {
		var total = 0;
		for (c in cs)
			switch (c) {
				case RGB(r, g, b):
					total += g;
				case Gray(g):
					total += g * 2;
			}
		return total;
	}

	static function binderInRange(cs:Array<Color>):Int {
		var total = 0;
		for (i in 0...cs.length)
			switch (cs[i]) {
				case RGB(_, g, _):
					total += g + i;
				case Gray(g):
					total += g * 2;
			}
		return total;
	}

	static function binderRes(rs:Array<Res>):String {
		var out = [];
		for (r in rs)
			switch (r) {
				case Ok(v):
					out.push('ok$v');
				case Error(g):
					out.push('err$g');
			}
		var i = 0;
		while (i < 2) {
			out.push("w" + i);
			i++;
		}
		return out.join(",");
	}

	static function binderMutated(c:Color, n:Int):Int {
		return switch (c) {
			case RGB(r, g, b):
				for (i in 0...n)
					g += i;
				g + r + b;
			case Gray(g):
				var k = 0;
				while (k < n) {
					g += 2;
					k++;
				}
				g;
		}
	}

	static function binderWithUserG(c:Color, n:Int):Int {
		var g = 1000;
		for (i in 0...n)
			g += i;
		var inner = switch (c) {
			case RGB(r, g, b): g;
			case Gray(g): g;
		}
		return g + inner;
	}

	static function arrayPattern(xs:Array<Int>, n:Int):Int {
		var s = 0;
		for (i in 0...n)
			s += i;
		return switch (xs) {
			case [1, g]: g + s;
			case [g, _, _]: g * 2 + s;
			default: s;
		}
	}

	static function main() {
		run("binderAfterLoop1", () -> binderAfterLoop(RGB(1, 2, 3), 4));
		run("binderAfterLoop2", () -> binderAfterLoop(Gray(5), 4));
		run("binderInLoop", () -> binderInLoop([RGB(1, 2, 3), Gray(5), RGB(0, 7, 0)]));
		run("binderInRange", () -> binderInRange([RGB(1, 2, 3), Gray(5), RGB(0, 7, 0)]));
		run("binderRes", () -> binderRes([Ok(1), Error("x"), Ok(2)]));
		run("binderMutated1", () -> binderMutated(RGB(1, 2, 3), 3));
		run("binderMutated2", () -> binderMutated(Gray(5), 3));
		run("binderWithUserG1", () -> binderWithUserG(RGB(1, 2, 3), 3));
		run("binderWithUserG2", () -> binderWithUserG(Gray(5), 3));
		run("arrayPattern1", () -> arrayPattern([1, 9], 3));
		run("arrayPattern2", () -> arrayPattern([4, 5, 6], 3));
	}
}
