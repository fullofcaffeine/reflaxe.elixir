/**
 * Regression for haxe.elixir.codex-dgx8: an array comprehension whose outer
 * loop becomes `Enum.reduce_while`, such as a loop over `m.keys()`, over an
 * iterator, or over a constant range that Haxe unrolls.
 *
 * Every element must reach the result. The compiler returned `[]`: the
 * function returned the empty initial list instead of the loop result, and an
 * inner loop over map keys started again from the empty list.
 * `expected.stdout` is the output of this program on the Haxe interpreter.
 * Results from map loops are sorted, because map order differs by target.
 */
@:keep
class Main {
	static function main():Void {
		final xs = [1, 2];
		final m = ["a" => 1, "b" => 2];
		final im = [1 => "one", 2 => "two"];
		final empty = new Map<String, Int>();
		final emptyInts = new Map<Int, String>();
		Sys.println("keysOnly " + keysOnly(m));
		Sys.println("keysNamed " + keysNamed(m));
		Sys.println("keysOuter " + keysOuter(m, xs));
		Sys.println("keysInner " + keysInner(xs, m));
		Sys.println("keysInKeys " + keysInKeys(m, im));
		Sys.println("valuesOuter " + valuesOuter(m, xs));
		Sys.println("iteratorOuter " + iteratorOuter(xs));
		Sys.println("rangeOuter " + rangeOuter(im));
		Sys.println("keysFilter " + keysFilter(m, [1, 2, 3]));
		Sys.println("emptyOuter " + keysOuter(empty, xs));
		Sys.println("emptyInner " + keysInKeys(m, emptyInts));
		Sys.println("emptyRange " + rangeOuter(emptyInts));
		Sys.println("keysArrayKeys " + keysArrayKeys(m, xs, im));
		Sys.println("rangeIfElse " + rangeIfElse([true, false], xs, im));
		Sys.println("whileAfterNested " + whileAfterNested(xs));
		Sys.println("whileAfterEmptyNested " + whileAfterNested([]));
	}

	/** One loop over map keys, returned directly. */
	public static function keysOnly(m:Map<String, Int>):String {
		return sorted([for (k in m.keys()) k]);
	}

	/** One loop over map keys, stored in a local before it is read. */
	public static function keysNamed(m:Map<String, Int>):String {
		final items = [for (k in m.keys()) k];
		return sorted(items);
	}

	/** The outer loop runs over map keys, the inner loop over an array. */
	public static function keysOuter(m:Map<String, Int>, xs:Array<Int>):String {
		return sorted([for (k in m.keys()) for (x in xs) k + x]);
	}

	/** The outer loop runs over an array, the inner loop over map keys. */
	public static function keysInner(xs:Array<Int>, m:Map<String, Int>):String {
		return sorted([for (x in xs) for (k in m.keys()) k + x]);
	}

	/** Both loops run over map keys. */
	public static function keysInKeys(m:Map<String, Int>, im:Map<Int, String>):String {
		return sorted([for (k in m.keys()) for (j in im.keys()) k + j]);
	}

	/** The outer loop runs over map values. */
	public static function valuesOuter(m:Map<String, Int>, xs:Array<Int>):String {
		return sorted([for (v in m) for (x in xs) Std.string(v * 10 + x)]);
	}

	/** The outer loop runs over an array iterator; its order is fixed, so it is not sorted. */
	public static function iteratorOuter(xs:Array<Int>):String {
		return [for (y in xs.iterator()) for (x in xs) x * 10 + y].join(",");
	}

	/** Haxe unrolls the constant range into one copy of the inner map loop per value. */
	public static function rangeOuter(im:Map<Int, String>):String {
		return sorted([for (i in 0...2) for (k in im.keys()) Std.string(i * 10 + k)]);
	}

	/** An `if` filter on each loop. */
	public static function keysFilter(m:Map<String, Int>, xs:Array<Int>):String {
		return sorted([
			for (k in m.keys())
				if (m.get(k) > 1) for (x in xs)
					if (x != m.get(k))
						k + x
		]);
	}

	/** A map loop inside an array loop inside a map loop: the innermost loop runs in an `Enum.reduce` callback. */
	public static function keysArrayKeys(m:Map<String, Int>, xs:Array<Int>, im:Map<Int, String>):String {
		return sorted([for (k in m.keys()) for (x in xs) for (j in im.keys()) k + x + j]);
	}

	/** An unrolled range with a branch: one arm nests a map loop in an array loop, the other has a map loop. */
	public static function rangeIfElse(flags:Array<Bool>, xs:Array<Int>, im:Map<Int, String>):String {
		return sorted([
			for (i in 0...2)
				if (flags[i]) for (x in xs) for (k in im.keys()) Std.string(x * 10 + k) else for (k in im.keys()) Std.string(k + 100)
		]);
	}

	/**
	 * A `while` loop inside a `for` loop, then a second `while` loop, all adding to one
	 * array. The local is named `g` on purpose: the loop lowering treats that name like
	 * a compiler temp. The second loop must start from the first loops' result, not from
	 * the `for` loop's callback state. With an empty `xs`, the second loop still runs.
	 */
	public static function whileAfterNested(xs:Array<Int>):String {
		var g:Array<Int> = [];
		for (x in xs) {
			var j = 0;
			while (j < 2) {
				g.push(x * 10 + j);
				j++;
			}
		}
		var i = 0;
		while (i < 2) {
			g.push(i);
			i++;
		}
		return g.join(",");
	}

	static function sorted(items:Array<String>):String {
		items.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return items.join(",");
	}
}
