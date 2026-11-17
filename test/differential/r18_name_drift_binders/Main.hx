// Differential fixture r18_name_drift_binders, from the PR #91 review probes (s01 shadowOfClosureArg,
// s06 lambdaArgInnerShadow and loopVarInnerShadow, r2 b01_nestedLoops, b02_threeLevels and
// b03_catchVarInnerShadow) for haxe.elixir.codex-hhp5.
// Haxe renames an inner shadow `q` to `q1`, `q2`, ... Two passes that match names by their shape
// treated `q1` as a drifted spelling of `q`:
// - LocalVarReferenceFix moved the reads of a closure argument, loop element or catch binder `q`
//   to the inner `q1`, because it did not count those binders as declared;
// - NumericSuffixVarNormalize renamed the binder `q1` but not its reads inside an interpolated
//   string, so the read was undefined and the declaration was dropped.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r18_name_drift_binders
enum Res {
	Ok(value:Int);
	Err(msg:String);
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	// A plain block inside a closure shadows the closure argument, which is read after.
	static function shadowOfClosureArg(n:Int):String {
		var f = function(q:Int):Int {
			{
				var q = 999;
				Sys.println("soca inner q=" + q);
			}
			return q * 2;
		};
		return "" + f(n);
	}

	// The same inside a map callback.
	static function lambdaArgInnerShadow(xs:Array<Int>):String {
		var ys = xs.map(function(q:Int):Int {
			{
				var q = 999;
				Sys.println("lais inner q=" + q);
			}
			return q + 1;
		});
		return ys.join(",");
	}

	// A for loop element with a nested shadow in the loop body, read after.
	static function loopVarInnerShadow(xs:Array<Int>):Int {
		var sum = 0;
		for (x in xs) {
			{
				var x = 999;
				Sys.println("lvis inner x=" + x);
			}
			sum += x;
		}
		return sum;
	}

	// A catch variable with a nested shadow, read after.
	static function catchVarInnerShadow(n:Int):String {
		try {
			if (n > 0)
				throw "boom";
			return "none";
		} catch (e:String) {
			{
				var e = "inner";
				Sys.println("cvis inner e=" + e);
			}
			return "caught " + e;
		}
	}

	// A match binder with a nested shadow, read after.
	static function binderInnerShadow(r:Res):String {
		switch (r) {
			case Ok(value):
				{
					var value = 999;
					Sys.println("bis inner value=" + value);
				}
				return "ok" + value;
			case Err(msg):
				return "err" + msg;
		}
	}

	// A comprehension element with a nested shadow, read after.
	static function compInnerShadow(xs:Array<Int>):String {
		var ys = [
			for (x in xs) {
				{
					var x = 999;
					Sys.println("cis inner x=" + x);
				}
				x * 3;
			}
		];
		return ys.join(",");
	}

	// Nested loops: an inner block shadows a loop-body local; both are read in a string.
	static function nestedLoops():String {
		var out = "";
		for (i in 0...2) {
			var q = i + 10;
			for (j in 0...2) {
				out += q + ",";
				{
					var q = 99;
					out += "(" + q + ")";
				}
			}
		}
		return out;
	}

	// Three nested blocks declare `q`; Haxe names them q, q1 and q2.
	static function threeLevels():String {
		var q = 1;
		var out = "";
		{
			var q = 2;
			{
				var q = 3;
				out += q;
			}
			out += q;
		}
		out += q;
		return out;
	}

	// Control: a program local whose own name ends in a digit, next to its base name.
	static function digitNamedLocals(n:Int):String {
		var v = n;
		var v2 = n * 2;
		var out = "";
		out += v + ":" + v2;
		return out;
	}

	static function main() {
		run("shadowOfClosureArg", () -> shadowOfClosureArg(4));
		run("lambdaArgInnerShadow", () -> lambdaArgInnerShadow([1, 2]));
		run("loopVarInnerShadow", () -> loopVarInnerShadow([1, 2]));
		run("catchVarInnerShadow", () -> catchVarInnerShadow(1));
		run("binderInnerShadow", () -> binderInnerShadow(Ok(5)));
		run("compInnerShadow", () -> compInnerShadow([1, 2]));
		run("nestedLoops", () -> nestedLoops());
		run("threeLevels", () -> threeLevels());
		run("digitNamedLocals", () -> digitNamedLocals(3));
	}
}
