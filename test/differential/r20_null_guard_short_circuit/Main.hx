// Differential fixture r20_null_guard_short_circuit (haxe.elixir.codex-8dnf).
// An early return guarded by `x == null || x.a == x.b` must test `x` for null
// before it reads a field of `x`. Haxe `||` and `&&` stop at the first operand
// that decides the result, so on a null `x` the field read never runs. A wrong
// lowering read `x.a` first and raised KeyError on nil.
// Each function runs once with a null value and once or more with a real value.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r20_null_guard_short_circuit
typedef Pair = {
	final a:Int;
	final b:Int;
}

typedef Outer = {
	final inner:Pair;
}

typedef Mut = {
	var a:Int;
	var b:Int;
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function find(x:Int):Null<Pair> {
		return x > 0 ? {a: x, b: 2} : null;
	}

	static function findOuter(x:Int):Null<Outer> {
		return x > 0 ? {inner: {a: x, b: 2}} : null;
	}

	static function findMut(x:Int):Null<Mut> {
		return x > 0 ? {a: x, b: 2} : null;
	}

	// A value from Dynamic that lacks the field `b` that its type requires.
	static function dyn(x:Int):Dynamic {
		return x > 0 ? {a: x} : null;
	}

	// The reported shape.
	static function reported(x:Int):Null<Int> {
		final head = find(x);
		if (head == null || head.a == head.b)
			return null;
		return head.a;
	}

	// `&&` under a negation: `!(h != null && h.a != h.b)` is the same guard.
	static function negatedAnd(x:Int):Null<Int> {
		final head = find(x);
		if (!(head != null && head.a != head.b))
			return null;
		return head.a;
	}

	// `&&` with a negated null test first.
	static function andNegatedNull(x:Int):Int {
		final head = find(x);
		if (!(head == null) && head.a < head.b)
			return head.a;
		return -1;
	}

	static function notNullAndPositive(x:Int):Int {
		final head = find(x);
		if (head != null && head.a > 0)
			return head.a;
		return -1;
	}

	// A field of a field.
	static function nestedField(x:Int):Null<Int> {
		final outer = findOuter(x);
		if (outer == null || outer.inner.a == outer.inner.b)
			return null;
		return outer.inner.a;
	}

	// A non-final local.
	static function varLocal(x:Int):Null<Int> {
		var head = find(x);
		if (head == null || head.a == head.b)
			return null;
		return head.a;
	}

	// The guard in a loop body.
	static function loopBody(n:Int):Int {
		var acc = 0;
		for (i in -1...n) {
			final head = find(i);
			if (head == null || head.a == head.b)
				continue;
			acc += head.a;
		}
		return acc;
	}

	// An early return from a loop body.
	static function loopReturn(n:Int):Int {
		for (i in -1...n) {
			final head = find(i);
			if (head == null || head.a == head.b)
				return i;
		}
		return -100;
	}

	// The guard as the condition of a value-returning ternary.
	static function ternary(x:Int):Int {
		final head = find(x);
		return (head == null || head.a == head.b) ? -1 : head.a;
	}

	// An older rewrite bound `v.a` to a new name `v_a` in a case clause up front. That
	// read the wrong value when a later `v.a` meant a new `v`, or when a local already
	// had the name `v_a`. Main returned silent wrong values for the nil-last shapes.
	static function rebindNilLast(x:Int, flag:Bool):Int {
		var v = find(x);
		if (flag || v == null)
			return -1;
		v = find(x + 10);
		return v.a;
	}

	static function rebindNilFirst(x:Int, flag:Bool):Int {
		var v = find(x);
		if (v == null || flag)
			return -1;
		v = find(x + 10);
		return v.a;
	}

	static function closureParam(x:Int, flag:Bool):Int {
		final v = find(x);
		final ps:Array<Pair> = [{a: 40, b: 0}];
		if (flag || v == null)
			return -1;
		return ps.map(v -> v.a)[0] + v.a;
	}

	static function binderNameNilLast(x:Int, flag:Bool):Int {
		final v = find(x);
		final v_a = 1000;
		if (flag || v == null)
			return -1;
		return v.a + v_a;
	}

	static function binderNameCamel(x:Int, flag:Bool):Int {
		final head = find(x);
		final headA = 1000;
		if (flag || head == null)
			return -1;
		return head.a + headA;
	}

	static function binderNameNilFirst(x:Int):Int {
		final head = find(x);
		final headA = 1000;
		if (head == null || head.a == head.b)
			return headA;
		return head.a;
	}

	// The second operand binds a variable (`n++`, `n += 1`, `v.a++`). The binding
	// must reach the code after the `if`. Only non-null values run here: for a null
	// value the compiler still runs the binding before the nil test
	// (an open gap, see the pass documentation).
	static function postIncr(x:Int):Int {
		var n = 2;
		var r = 0;
		final v = find(x);
		if (v == null || v.a == n++)
			r = 1;
		else
			r = v.b;
		return n * 100 + r;
	}

	static function preIncr(x:Int):Int {
		var n = 2;
		var r = 0;
		final v = find(x);
		if (v == null || v.a == ++n)
			r = 1;
		else
			r = v.b;
		return n * 100 + r;
	}

	static function postDecr(x:Int):Int {
		var n = 2;
		var r = 0;
		final v = find(x);
		if (v == null || v.a == n--)
			r = 1;
		else
			r = v.b;
		return n * 100 + r;
	}

	static function plusAssign(x:Int):Int {
		var n = 2;
		var r = 0;
		final v = find(x);
		if (v == null || v.a == (n += 1))
			r = 1;
		else
			r = v.b;
		return n * 100 + r;
	}

	static function incrTernary(x:Int):Int {
		var n = 2;
		final v = find(x);
		final r = (v == null || v.a == n++) ? 1 : v.b;
		return n * 100 + r;
	}

	static function indexIncr(x:Int):Int {
		final kinds = [2, 9, 9];
		var pos = 0;
		final v = find(x);
		final r = (v == null || v.a == kinds[pos++]) ? 1 : v.b;
		return pos * 100 + r;
	}

	static function condFieldIncr(x:Int):Int {
		final v = findMut(x);
		var r = 0;
		if (v == null || v.a++ == v.b)
			r = 1;
		else
			r = v.b;
		return (v == null ? 0 : v.a * 100) + r;
	}

	// The counter moves only in the guard and also ends the loop.
	static function whileIncr(m:Int):Int {
		var i = 0;
		var guard = 0;
		var sum = 0;
		while (i < m && guard < 50) {
			guard++;
			final v = find(i + 1);
			if (v == null || v.a == i++ * 0 + 2)
				sum += 1000;
			else
				sum += v.a;
		}
		return guard * 100000 + sum;
	}

	// The increment runs first in the source too.
	static function incrNilLast(x:Int):Int {
		var n = 2;
		var r = 0;
		final v = find(x);
		if (x == n++ || v == null)
			r = 1;
		else
			r = v.b;
		return n * 100 + r;
	}

	// The value lacks `b`. Haxe reads a missing field as null only when it runs
	// the read, so the guard must not read every field up front.
	static function missingKeyFlag(x:Int, flag:Bool):Int {
		final d:Dynamic = dyn(x);
		final p:Null<Pair> = d;
		if (p == null || flag)
			return -1;
		return p.a;
	}

	static function missingKeyCondRead(x:Int):Int {
		final d:Dynamic = dyn(x);
		final p:Null<Pair> = d;
		if (p == null || p.a == 3)
			return -1;
		return p.a == 1 ? -3 : p.b;
	}

	// Controls: shapes that main already gets right.
	static function splitIf(x:Int):Null<Int> {
		final head = find(x);
		if (head == null)
			return null;
		if (head.a == head.b)
			return null;
		return head.a;
	}

	static function nullOnly(x:Int):Int {
		final head = find(x);
		if (head == null)
			return -1;
		return head.a;
	}

	static function ternaryNotNull(x:Int):Int {
		final head = find(x);
		return head != null ? head.a : -1;
	}

	static function orNoEarlyReturn(x:Int):Bool {
		final head = find(x);
		final skip = head == null || head.a == head.b;
		return skip;
	}

	static function main() {
		run("reported0", () -> reported(0));
		run("reported1", () -> reported(1));
		run("reported2", () -> reported(2));
		run("negatedAnd0", () -> negatedAnd(0));
		run("negatedAnd1", () -> negatedAnd(1));
		run("negatedAnd2", () -> negatedAnd(2));
		run("andNegatedNull0", () -> andNegatedNull(0));
		run("andNegatedNull1", () -> andNegatedNull(1));
		run("andNegatedNull3", () -> andNegatedNull(3));
		run("notNullAndPositive0", () -> notNullAndPositive(0));
		run("notNullAndPositive1", () -> notNullAndPositive(1));
		run("nestedField0", () -> nestedField(0));
		run("nestedField1", () -> nestedField(1));
		run("nestedField2", () -> nestedField(2));
		run("varLocal0", () -> varLocal(0));
		run("varLocal1", () -> varLocal(1));
		run("varLocal2", () -> varLocal(2));
		run("loopBody", () -> loopBody(4));
		run("loopReturn", () -> loopReturn(4));
		run("ternary0", () -> ternary(0));
		run("ternary1", () -> ternary(1));
		run("ternary2", () -> ternary(2));
		run("rebindNilLast", () -> rebindNilLast(3, false));
		run("rebindNilFirst0", () -> rebindNilFirst(0, false));
		run("rebindNilFirst3", () -> rebindNilFirst(3, false));
		run("closureParam", () -> closureParam(3, false));
		run("binderNameNilLast", () -> binderNameNilLast(3, false));
		run("binderNameCamel", () -> binderNameCamel(3, false));
		run("binderNameNilFirst0", () -> binderNameNilFirst(0));
		run("binderNameNilFirst2", () -> binderNameNilFirst(2));
		run("binderNameNilFirst3", () -> binderNameNilFirst(3));
		for (x in [2, 3]) {
			run("postIncr" + x, () -> postIncr(x));
			run("preIncr" + x, () -> preIncr(x));
			run("postDecr" + x, () -> postDecr(x));
			run("plusAssign" + x, () -> plusAssign(x));
			run("incrTernary" + x, () -> incrTernary(x));
			run("indexIncr" + x, () -> indexIncr(x));
			run("condFieldIncr" + x, () -> condFieldIncr(x));
		}
		run("whileIncr", () -> whileIncr(4));
		run("incrNilLast0", () -> incrNilLast(0));
		run("incrNilLast2", () -> incrNilLast(2));
		run("incrNilLast3", () -> incrNilLast(3));
		run("missingKeyFlag0", () -> missingKeyFlag(0, false));
		run("missingKeyFlag3", () -> missingKeyFlag(3, true));
		run("missingKeyFlag4", () -> missingKeyFlag(4, false));
		run("missingKeyCondRead0", () -> missingKeyCondRead(0));
		run("missingKeyCondRead1", () -> missingKeyCondRead(1));
		run("missingKeyCondRead3", () -> missingKeyCondRead(3));
		run("splitIf0", () -> splitIf(0));
		run("splitIf1", () -> splitIf(1));
		run("nullOnly0", () -> nullOnly(0));
		run("nullOnly1", () -> nullOnly(1));
		run("ternaryNotNull0", () -> ternaryNotNull(0));
		run("ternaryNotNull1", () -> ternaryNotNull(1));
		run("orNoEarlyReturn0", () -> orNoEarlyReturn(0));
		run("orNoEarlyReturn2", () -> orNoEarlyReturn(2));
	}
}
