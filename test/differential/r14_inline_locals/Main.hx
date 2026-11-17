// Differential fixture r14_inline_locals, from the PR #90 review probes (an inlined function's own local
// has the same Haxe name as a caller local that is read after the call).
// Haxe gives each block its own scope; Elixir has none, so the inner local must not overwrite the outer one.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r14_inline_locals
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static inline function inlSumG(xs:Array<Int>):Int {
		var g = 0;
		for (x in xs)
			g += x;
		return g;
	}

	static inline function inlSumQ(xs:Array<Int>):Int {
		var q = 0;
		for (x in xs)
			q += x;
		return q;
	}

	// Probe useG: the caller's g and the inlined function's g.
	static function useG(xs:Array<Int>):Int {
		var g = 100;
		var a = inlSumG(xs);
		g += a;
		return g + inlSumG([1, 2]);
	}

	// Probe useQ: the same shape with an ordinary name.
	static function useQ(xs:Array<Int>):Int {
		var q = 100;
		var a = inlSumQ(xs);
		q += a;
		return q + inlSumQ([1, 2]);
	}

	static inline function inlSeveral(n:Int):Int {
		var a = n * 2;
		var b = a + 1;
		var c = b * a;
		return a + b + c;
	}

	// An inlined function with several locals, all named like caller locals.
	static function useSeveral(n:Int):String {
		var a = 1;
		var b = 2;
		var c = 3;
		var r = inlSeveral(n);
		return a + "," + b + "," + c + "," + r;
	}

	static inline function inlInner(n:Int):Int {
		var t = n + 10;
		return t * 2;
	}

	static inline function inlOuter(n:Int):Int {
		var t = n + 1;
		var u = inlInner(t);
		return t + u;
	}

	// Nested inlining: the caller, the outer inline and the inner inline all declare t.
	static function useNested(n:Int):String {
		var t = 1000;
		var r = inlOuter(n);
		return t + ":" + r;
	}

	static inline function inlTwice(n:Int):Int {
		var k = n * 3;
		return k + 1;
	}

	// One inline function called twice in one expression, between reads of the caller's k.
	static function useTwiceInExpr(n:Int):Int {
		var k = 7;
		return k + inlTwice(n) + k + inlTwice(n + 1) + k;
	}

	static inline function inlCapture(n:Int):Void->Int {
		var v = n + 5;
		return () -> v * 2;
	}

	// An inlined local captured by a closure; the caller's v is read afterwards.
	static function useCapture(n:Int):String {
		var v = 3;
		var f = inlCapture(n);
		var first = f();
		return v + "/" + first + "/" + f();
	}

	static inline function inlLoop(n:Int):Int {
		var s = 0;
		var i = 0;
		while (i < n) {
			s += i;
			i++;
		}
		return s;
	}

	// An inlined loop whose accumulator and counter share names with caller locals.
	static function useLoop(n:Int):String {
		var s = 50;
		var i = 9;
		var total = inlLoop(n);
		s += 1;
		return s + "|" + i + "|" + total;
	}

	// A plain nested block that shadows an outer local which is read after the block.
	static function useBlockShadow(n:Int):Int {
		var w = 10;
		if (n > 0) {
			var w = n * 100;
			w += 1;
			Sys.println("inner w=" + w);
		}
		return w;
	}

	// Control: the inner local shadows a caller local that is never read afterwards.
	static function useDeadOuter(xs:Array<Int>):Int {
		var q = 100;
		Sys.println("outer q=" + q);
		return inlSumQ(xs);
	}

	// Control: the caller reassigns its local after the call; the inner value must not leak in.
	static function useReassignAfter(xs:Array<Int>):Int {
		var q = 1;
		var a = inlSumQ(xs);
		q = q * 10 + a;
		return q;
	}

	static inline function inlArgReuse(base:Int):Int {
		var t = base + 1;
		return t * 10 + base;
	}

	// The caller passes its own t, and the inlined body declares t too: the inlined block
	// reads the caller's t after its own t is bound.
	static function useArgReuse(n:Int):String {
		var t = n;
		var r = inlArgReuse(t);
		return t + "~" + r;
	}

	// A nested block in a loop body shadows the accumulator that the loop updates.
	static function useLoopBodyShadow(xs:Array<Int>):Int {
		var s = 0;
		for (x in xs) {
			s += x;
			{
				var s = x * 100;
				Sys.println("loop inner s=" + s);
			}
		}
		return s;
	}

	// A nested block inside an if branch shadows a local that the same branch updates.
	static function useBranchShadow(n:Int):Int {
		var w = 10;
		if (n > 0) {
			w += 1;
			{
				var w = 500;
				Sys.println("branch inner w=" + w);
			}
			w += 2;
		}
		return w;
	}

	// The shadowing local is captured by a closure that runs after the block.
	static function useClosureAfterBlock(n:Int):String {
		var c = n;
		var f:Void->Int = null;
		{
			var c = n * 7;
			f = () -> c;
		}
		return c + "^" + f();
	}

	static function main() {
		run("useG", () -> useG([1, 2, 3]));
		run("useQ", () -> useQ([1, 2, 3]));
		run("useSeveral", () -> useSeveral(4));
		run("useNested", () -> useNested(2));
		run("useTwiceInExpr", () -> useTwiceInExpr(2));
		run("useCapture", () -> useCapture(1));
		run("useLoop", () -> useLoop(4));
		run("useBlockShadow", () -> useBlockShadow(2));
		run("useDeadOuter", () -> useDeadOuter([4, 5]));
		run("useReassignAfter", () -> useReassignAfter([4, 5]));
		run("useArgReuse", () -> useArgReuse(3));
		run("useLoopBodyShadow", () -> useLoopBodyShadow([1, 2]));
		run("useBranchShadow", () -> useBranchShadow(1));
		run("useClosureAfterBlock", () -> useClosureAfterBlock(2));
	}
}
