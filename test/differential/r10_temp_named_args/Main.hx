// Differential fixture r10_temp_named_args, from haxe.elixir.codex-z0lk (arguments and
// program locals named like Haxe temps: g, _g, next to a Haxe loop temp).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r10_temp_named_args
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function argInterp(g:String, n:Int):String {
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return g + acc;
	}

	static function argPlain(g:Int, n:Int):Int {
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return g * 100 + acc;
	}

	static function argOnlyGPlain(r:Verdict, g:String, n:Int):String {
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return switch (r) {
			case Ok(v):
				g + acc;
			case Error(e):
				"e" + e;
		};
	}

	static function underG(n:Int):Int {
		var _g = 5;
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return _g * 100 + acc;
	}

	static function underGMut(n:Int):Int {
		var _g = 5;
		for (i in 0...n)
			_g += i;
		return _g;
	}

	static function underGArg(_g:Int, n:Int):Int {
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return _g * 100 + acc;
	}

	static function underGOnly(r:Verdict, n:Int):String {
		var _g = "UG";
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return switch (r) {
			case Ok(v):
				_g + acc;
			case Error(e):
				"e" + e;
		};
	}

	static function argG1Mut(g1:Int, n:Int):Int {
		for (i in 0...n)
			g1 += i;
		return g1;
	}

	static function argTemplate(g:String, n:Int):String {
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return '$g-$acc';
	}

	static function elseAliasArg(c:Bool, g:Int):Int {
		var h = 0;
		if (c) {
			g = 1;
			h = 2;
		} else {
			h = g;
		}
		return g + h;
	}

	static function closureArg(n:Int):Int {
		var f = function(g:Int):Int {
			var acc = 0;
			for (i in 0...n)
				acc += i;
			return g * 100 + acc;
		};
		return f(7);
	}

	static function catchG(n:Int):String {
		var out = "none";
		try {
			throw "E";
		} catch (g:String) {
			var acc = 0;
			for (i in 0...n)
				acc += i;
			out = g + acc;
		}
		return out;
	}

	static function underGArr(xs:Array<Int>):Int {
		var _g = 5;
		var acc = 0;
		for (x in xs)
			acc += x;
		return _g * 100 + acc;
	}

	static function underGMap(m:Map<String, Int>):Int {
		var _g = 5;
		var acc = 0;
		for (k => v in m)
			acc += v;
		return _g * 100 + acc;
	}

	static function underGInside(n:Int):Int {
		var _g = 5;
		var s = 0;
		for (i in 0...n)
			s += i * _g;
		return _g + s;
	}

	static function underGBoth(n:Int):Int {
		var g = 1;
		var _g = 2;
		for (i in 0...n)
			g += i;
		return g * 10 + _g;
	}

	static function underGInterp(n:Int):String {
		var _g = "U";
		var acc = 0;
		for (i in 0...n)
			acc += i;
		return '$_g-$acc';
	}

	static function underGArrPush(xs:Array<Int>):String {
		var _g = [];
		for (x in xs)
			_g.push(x * 2);
		return _g.join(",");
	}

	static function underG1(xs:Array<Int>):Int {
		var _g1 = 3;
		var acc = 0;
		for (x in xs)
			acc += x;
		return _g1 * 100 + acc;
	}

	static function main() {
		run("argInterp", () -> argInterp("A", 4));
		run("argPlain", () -> argPlain(7, 4));
		run("argOnlyGPlainOk", () -> argOnlyGPlain(Ok("o"), "A", 4));
		run("argOnlyGPlainErr", () -> argOnlyGPlain(Error("x"), "A", 4));
		run("argG1Mut", () -> argG1Mut(5, 3));
		run("argTemplate", () -> argTemplate("A", 4));
		run("elseAliasArg1", () -> elseAliasArg(true, 5));
		run("elseAliasArg2", () -> elseAliasArg(false, 5));
		run("closureArg", () -> closureArg(4));
		run("catchG", () -> catchG(4));
		run("underG", () -> underG(4));
		run("underGMut", () -> underGMut(4));
		run("underGArg", () -> underGArg(7, 4));
		run("underGOnly", () -> underGOnly(Ok("o"), 4));
		run("underGArr", () -> underGArr([1, 2, 3]));
		run("underGMap", () -> underGMap(["a" => 1, "b" => 2]));
		run("underGInside", () -> underGInside(4));
		run("underGBoth", () -> underGBoth(4));
		run("underGInterp", () -> underGInterp(4));
		run("underGArrPush", () -> underGArrPush([1, 2, 3]));
		run("underG1", () -> underG1([1, 2, 3]));
	}
}
