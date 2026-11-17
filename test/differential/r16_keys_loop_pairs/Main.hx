// Differential fixture r16_keys_loop_pairs, from the PR #90 and PR #91 review probes
// (haxe.elixir.codex-p2ms). A loop over map keys is lowered to
// `while (it.hasNext()) { var x = it.next(); ... }`. The compiler must pair the
// iterator `it` with its loop variable `x` by this shape, not by name: Haxe can name
// them apart (`g1` and `g`), and the program can hold the iterator itself.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r16_keys_loop_pairs
class ListNode {
	public var v:Int;
	public var tail:Null<ListNode>;

	public function new(v:Int, tail:Null<ListNode>) {
		this.v = v;
		this.tail = tail;
	}

	public function next():ListNode
		return tail == null ? this : tail;
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static inline function inlSum(xs:Array<Int>):Int {
		var g = 0;
		for (x in xs)
			g += x;
		return g;
	}

	// Haxe names the inner iterator g1 and its loop variable g: the outer g is read after.
	static function nestedOuterAfter(m:Map<Int, Int>, n:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys()) {
			for (g in n.keys())
				acc += g;
			acc += g * 100;
		}
		return acc;
	}

	// The same loop with the outer read before the inner loop: Haxe keeps one name.
	static function nestedOuterBefore(m:Map<Int, Int>, n:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys()) {
			acc += g * 100;
			for (g in n.keys())
				acc += g;
		}
		return acc;
	}

	static function nestedSame(m:Map<Int, Int>, n:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys()) {
			for (g in n.keys())
				acc += g;
		}
		return acc;
	}

	static function nestedMixed(m:Map<Int, Int>, n:Map<Int, Int>):Int {
		var acc = 0;
		for (k in m.keys())
			for (g in n.keys())
				acc += k * 10 + g;
		return acc;
	}

	// A local g is read after a block with its own keys loop over g.
	static function localThenLoop(m:Map<Int, Int>):Int {
		var g = 5;
		var acc = 0;
		for (k in m.keys())
			acc += k * g;
		{
			for (g in m.keys())
				acc += g;
		}
		return acc + g * 1000;
	}

	// An argument g is read after a block with a keys loop over g.
	static function argThenLoop(g:Int, m:Map<Int, Int>):Int {
		var acc = 0;
		{
			for (g in m.keys())
				acc += g;
		}
		return acc + g * 1000;
	}

	// The same with the name k: an outer k is read after the keys loop.
	static function forKeysShadow():String {
		var k = "outer";
		var m = ["a" => 1];
		var out = "";
		for (k in m.keys())
			out += k;
		return k + ":" + out;
	}

	// A caller local g, an inlined local g and a keys loop over g in one function.
	static function gAll(xs:Array<Int>):String {
		var g = 100;
		var a = inlSum(xs);
		var m = ["k" => 1];
		var out = "";
		for (g in m.keys())
			out += g;
		g += a;
		return g + ":" + out + ":" + inlSum([1, 2]);
	}

	static function zAll(xs:Array<Int>):String {
		var z = 100;
		var a = inlSum(xs);
		var m = ["k" => 1];
		var out = "";
		for (z in m.keys())
			out += z;
		z += a;
		return z + ":" + out + ":" + inlSum([1, 2]);
	}

	static function gArg(g:Int, xs:Array<Int>):String {
		var a = inlSum(xs);
		var m = ["k" => 1];
		var out = "";
		for (g in m.keys())
			out += g;
		return g + ":" + a + ":" + out;
	}

	static function zArg(z:Int, xs:Array<Int>):String {
		var a = inlSum(xs);
		var m = ["k" => 1];
		var out = "";
		for (z in m.keys())
			out += z;
		return z + ":" + a + ":" + out;
	}

	// Two keys loops with the same names, then a local with that name: each later name is
	// bound again before it is read, so each loop can drop its iterator.
	static function seqThenLocal(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys())
			acc += g;
		for (g in m.keys())
			acc += g * 10;
		var g = 5;
		return acc + g * 1000;
	}

	// The program holds the keys iterator: `for (g in it)`.
	static function progIter(m:Map<Int, Int>):Int {
		var it = m.keys();
		var acc = 0;
		for (g in it)
			acc += g;
		return acc;
	}

	// The program iterator itself is named g.
	static function iterNamedG(m:Map<Int, Int>):Int {
		var g = m.keys();
		var acc = 0;
		for (x in g)
			acc += x;
		return acc;
	}

	// for (g in g).
	static function gInG(m:Map<Int, Int>):Int {
		var g = m.keys();
		var acc = 0;
		for (g in g)
			acc += g;
		return acc;
	}

	// A hand-written loop with another name for the element.
	static function manualDiff(m:Map<Int, Int>):Int {
		var it = m.keys();
		var acc = 0;
		while (it.hasNext()) {
			var x = it.next();
			acc += x;
		}
		return acc;
	}

	// A hand-written loop with the shape that Haxe gives a for loop.
	static function manualSame(m:Map<Int, Int>):Int {
		var acc = 0;
		var g = m.keys();
		while (g.hasNext()) {
			var g = g.next();
			acc += g;
		}
		return acc;
	}

	// Iterators that are not map keys keep the iterator protocol.
	static function argIter(g:Iterator<Int>):Int {
		var acc = 0;
		for (x in g)
			acc += x;
		return acc;
	}

	static function argIterG(g:Iterator<Int>):Int {
		var acc = 0;
		for (g in g)
			acc += g;
		return acc;
	}

	static function reassign(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys()) {
			g = g * 2;
			acc += g;
		}
		return acc;
	}

	static function withBreak(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys()) {
			if (g == 99)
				break;
			if (g == 2)
				continue;
			acc += g;
		}
		return acc;
	}

	static function captured(m:Map<Int, Int>):Int {
		var fs = [];
		for (g in m.keys())
			fs.push(() -> g * 2);
		var acc = 0;
		for (f in fs)
			acc += f();
		return acc;
	}

	static function readsMap(m:Map<Int, Int>):Int {
		var acc = 0;
		for (g in m.keys())
			acc += g * m.get(g);
		return acc;
	}

	static function keyValueShadow():String {
		var k = "outer";
		var v = 100;
		var m = ["a" => 1];
		var out = "";
		for (k => v in m)
			out += k + v;
		return k + ":" + v + ":" + out;
	}

	// `var g = g.next()` outside a hasNext loop is not an iterator pair.
	static function shadowNext():Int {
		var g = new ListNode(1, new ListNode(2, null));
		var acc = 0;
		{
			var g = g.next();
			acc += g.v;
		}
		return acc * 10 + g.v;
	}

	static function shadowNextUnread():Int {
		var g = new ListNode(1, new ListNode(2, null));
		var acc = 0;
		{
			var g = g.next();
			acc += g.v;
		}
		return acc;
	}

	static function shadowNextArg(g:ListNode):Int {
		var acc = 0;
		{
			var g = g.next();
			acc += g.v;
		}
		return acc * 10 + g.v;
	}

	static function main() {
		run("nestedOuterAfter", () -> nestedOuterAfter([1 => 10, 2 => 20], [5 => 1, 6 => 2]));
		run("nestedOuterBefore", () -> nestedOuterBefore([1 => 10, 2 => 20], [5 => 1, 6 => 2]));
		run("nestedSame", () -> nestedSame([1 => 10, 2 => 20], [5 => 1, 6 => 2]));
		run("nestedMixed", () -> nestedMixed([1 => 10, 2 => 20], [5 => 1, 6 => 2]));
		run("localThenLoop", () -> localThenLoop([1 => 10, 2 => 20, 3 => 30]));
		run("argThenLoop", () -> argThenLoop(5, [1 => 10, 2 => 20, 3 => 30]));
		run("forKeysShadow", () -> forKeysShadow());
		run("gAll", () -> gAll([1, 2, 3]));
		run("zAll", () -> zAll([1, 2, 3]));
		run("gArg", () -> gArg(100, [1, 2, 3]));
		run("zArg", () -> zArg(100, [1, 2, 3]));
		run("seqThenLocal", () -> seqThenLocal([1 => 10, 2 => 20, 3 => 30]));
		run("progIter", () -> progIter([1 => 10, 2 => 20, 3 => 30]));
		run("iterNamedG", () -> iterNamedG([1 => 10, 2 => 20, 3 => 30]));
		run("gInG", () -> gInG([1 => 10, 2 => 20, 3 => 30]));
		run("manualDiff", () -> manualDiff([1 => 10, 2 => 20, 3 => 30]));
		run("manualSame", () -> manualSame([1 => 10, 2 => 20, 3 => 30]));
		run("argIter", () -> argIter([1, 2, 3].iterator()));
		run("argIterG", () -> argIterG([1, 2, 3].iterator()));
		run("reassign", () -> reassign([1 => 10, 2 => 20, 3 => 30]));
		run("withBreak", () -> withBreak([1 => 10, 2 => 20, 3 => 30]));
		run("captured", () -> captured([1 => 10, 2 => 20, 3 => 30]));
		run("readsMap", () -> readsMap([1 => 10, 2 => 20, 3 => 30]));
		run("keyValueShadow", () -> keyValueShadow());
		run("shadowNext", () -> shadowNext());
		run("shadowNextUnread", () -> shadowNextUnread());
		run("shadowNextArg", () -> shadowNextArg(new ListNode(1, new ListNode(2, null))));
	}
}
