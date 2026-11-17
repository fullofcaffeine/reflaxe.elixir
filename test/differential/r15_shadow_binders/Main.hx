// Differential fixture r15_shadow_binders, from the PR #91 review probes (s06, s07, s02split t01/t08, s08 u01-u08,
// round 3: chain40, a04, a21).
// A loop element, range index, comprehension variable, iterator element or closure argument has the
// name of an outer local. Elixir already scopes these binders, so a rename must not break them, and a
// rename inside them must not use a name that name-drift passes treat as the same variable.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r15_shadow_binders
// A small user iterator: `next()` outside a loop is an ordinary call.
class Lexer {
	var i = 0;
	var toks:Array<String>;

	public function new(toks:Array<String>) {
		this.toks = toks;
	}

	public function hasNext():Bool
		return i < toks.length;

	public function next():String
		return toks[i++];
}

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

	static inline function bump(n:Int):Int {
		var t = n + 1;
		return t * 2;
	}

	// One inline helper called 40 times; the caller's t is read after. The inlined t locals
	// are never live together, so they share one name (no growing name chain).
	static function manyCalls():String {
		var t = 1000;
		var sum = 0;
		sum += bump(0);
		sum += bump(1);
		sum += bump(2);
		sum += bump(3);
		sum += bump(4);
		sum += bump(5);
		sum += bump(6);
		sum += bump(7);
		sum += bump(8);
		sum += bump(9);
		sum += bump(10);
		sum += bump(11);
		sum += bump(12);
		sum += bump(13);
		sum += bump(14);
		sum += bump(15);
		sum += bump(16);
		sum += bump(17);
		sum += bump(18);
		sum += bump(19);
		sum += bump(20);
		sum += bump(21);
		sum += bump(22);
		sum += bump(23);
		sum += bump(24);
		sum += bump(25);
		sum += bump(26);
		sum += bump(27);
		sum += bump(28);
		sum += bump(29);
		sum += bump(30);
		sum += bump(31);
		sum += bump(32);
		sum += bump(33);
		sum += bump(34);
		sum += bump(35);
		sum += bump(36);
		sum += bump(37);
		sum += bump(38);
		sum += bump(39);
		return t + ":" + sum;
	}

	static inline function nest(n:Int):Int {
		var t = n * 10;
		var u = bump(t);
		return t + u;
	}

	// Two shadows of t live at the same time (nest's t is read after bump's t), plus the caller's t.
	static function twoLiveShadows(n:Int):String {
		var t = 7;
		var r = nest(n);
		return t + ":" + r;
	}

	// Three levels of block shadows in branches.
	static function threeLevelBranches(c:Bool):String {
		var q = 1;
		var out = "";
		if (c) {
			var q = 2;
			if (c) {
				var q = 3;
				out += q;
			}
			out += q;
		}
		out += q;
		return out;
	}

	static inline function peekLen(lx:Lexer):Int {
		var tok = lx.next();
		return tok.length;
	}

	// An inlined `var tok = lx.next()` that is not a loop element; the caller's tok is read after.
	static function inlineNextCall(toks:Array<String>):String {
		var tok = "outer";
		var lx = new Lexer(toks);
		var n = peekLen(lx);
		return tok + ":" + n;
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
		run("manyCalls", () -> manyCalls());
		run("twoLiveShadows", () -> twoLiveShadows(2));
		run("threeLevelBranches", () -> threeLevelBranches(true));
		run("inlineNextCall", () -> inlineNextCall(["abc", "d"]));
	}
}
