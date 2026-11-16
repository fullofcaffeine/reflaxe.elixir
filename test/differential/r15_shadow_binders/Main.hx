// Differential fixture r15_shadow_binders, from the PR #91 review probes (s06, s07, s02split t01/t08, s08 u01-u08).
// A loop element, range index, comprehension variable, iterator element or closure argument has the
// name of an outer local. Elixir already scopes these binders, so a rename must not break them, and a
// rename inside them must not use a name that name-drift passes treat as the same variable.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r15_shadow_binders
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	// A for loop variable over an array shadows an outer local that is read after.
	static function forVarShadow(xs:Array<Int>):String {
		var x = 100;
		var sum = 0;
		for (x in xs)
			sum += x;
		return x + ":" + sum;
	}

	// The loop body is a block with a call.
	static function loopVarOuter(xs:Array<Int>):String {
		var x = 100;
		var out = "";
		for (x in xs) {
			out += "[" + x + "]";
		}
		return x + ":" + out;
	}

	// The same over a range.
	static function rangeVarOuter(n:Int):String {
		var i = 100;
		var out = "";
		for (i in 0...n) {
			out += "[" + i + "]";
		}
		return i + ":" + out;
	}

	// Two sibling loops with the same loop variable name, and an outer local of that name.
	static function siblingLoops(xs:Array<Int>):String {
		var i = 42;
		var a = 0;
		for (i in 0...3)
			a += i;
		for (i in xs)
			a += i;
		return i + ":" + a;
	}

	// An array comprehension whose variable has the name of an outer local read after.
	static function compShadow(xs:Array<Int>):String {
		var x = 100;
		var ys = [for (x in xs) x * 2];
		return x + ":" + ys.join(",");
	}

	// A filtering comprehension.
	static function filterOuter(xs:Array<Int>):String {
		var x = 2;
		var ys = [for (x in xs) if (x % 2 == 0) x * 10];
		return x + ":" + ys.join(",");
	}

	static inline function total(xs:Array<Int>):Int {
		var t = 0;
		for (x in xs)
			t += x;
		return t;
	}

	// An inlined loop whose loop variable has the name of a caller local read after.
	static function inlineLoopVarOuter(xs:Array<Int>):String {
		var x = 100;
		var r = total(xs);
		return x + ":" + r;
	}

	static inline function inlKeys(m:Map<String, Int>):String {
		var acc = "";
		for (k in m.keys())
			acc += k;
		return acc;
	}

	// An inlined keys loop; the caller has a local named like the loop variable, read after.
	static function inlineKeysOuterK():String {
		var k = "outer";
		var r = inlKeys(["a" => 1]);
		return k + ":" + r;
	}

	// A keys loop in an if branch; an outer local with the loop variable's name is read after.
	static function branchKeysOuterK(c:Bool):String {
		var k = "outer";
		var out = "";
		var m = ["a" => 1];
		if (c) {
			for (k in m.keys())
				out += k;
		}
		return k + ":" + out;
	}

	// The same with an argument named like the loop variable.
	static function branchKeysArgK(k:String, c:Bool):String {
		var out = "";
		var m = ["a" => 1];
		if (c) {
			for (k in m.keys())
				out += k;
		}
		return k + ":" + out;
	}

	// A keys loop inside an outer loop body; the outer local is read after.
	static function loopBodyKeysOuterK(n:Int):String {
		var k = "outer";
		var out = "";
		var m = ["a" => 1];
		for (i in 0...n) {
			for (k in m.keys())
				out += k + i;
		}
		return k + ":" + out;
	}

	// A loop variable; an if branch in the loop body declares the same name; the loop variable is read after.
	static function loopVarBranchShadow(xs:Array<Int>):Int {
		var sum = 0;
		for (x in xs) {
			if (x > 1) {
				var x = 999;
				Sys.println("lvbs inner x=" + x);
			}
			sum += x;
		}
		return sum;
	}

	// A closure argument; an if branch inside the closure declares the same name; the argument is read after.
	static function closureArgBranchShadow(n:Int):String {
		var twice = function(q:Int):Int {
			if (q > 0) {
				var q = 999;
				Sys.println("cabs inner q=" + q);
			}
			return q * 2;
		};
		return "" + twice(n);
	}

	// A map callback argument; an if branch declares the same name; the argument is read after.
	static function lambdaArgBranchShadow(xs:Array<Int>):String {
		var ys = xs.map(function(q:Int):Int {
			if (q > 1) {
				var q = 999;
				Sys.println("labs inner q=" + q);
			}
			return q + 1;
		});
		return ys.join(",");
	}

	static function main() {
		run("forVarShadow", () -> forVarShadow([1, 2, 3]));
		run("loopVarOuter", () -> loopVarOuter([1, 2]));
		run("rangeVarOuter", () -> rangeVarOuter(2));
		run("siblingLoops", () -> siblingLoops([5, 6]));
		run("compShadow", () -> compShadow([1, 2, 3]));
		run("filterOuter", () -> filterOuter([1, 2, 3, 4]));
		run("inlineLoopVarOuter", () -> inlineLoopVarOuter([1, 2, 3]));
		run("inlineKeysOuterK", () -> inlineKeysOuterK());
		run("branchKeysOuterK", () -> branchKeysOuterK(true));
		run("branchKeysArgK", () -> branchKeysArgK("outer", true));
		run("loopBodyKeysOuterK", () -> loopBodyKeysOuterK(2));
		run("loopVarBranchShadow", () -> loopVarBranchShadow([1, 2, 3]));
		run("closureArgBranchShadow", () -> closureArgBranchShadow(3));
		run("lambdaArgBranchShadow", () -> lambdaArgBranchShadow([1, 2, 3]));
	}
}
