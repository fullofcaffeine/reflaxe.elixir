/**
 * `array.push` in a loop must take time in proportion to the number of items.
 *
 * `runtime.exs` calls these functions from Elixir. It compares the results
 * with the Haxe interpreter and collects 200,000 items with a time budget.
 */

/** Holds an array, to nest inside `Step.Cont`. */
enum Box {
	Box(values:Array<Int>);
}

/**
 * `Cont` compiles to the tuple `{:cont, value}`, which is also the tuple that a
 * generated loop returns to go on. The compiler must not mix them up.
 */
enum Step {
	Cont(box:Box);
	Plain(values:Array<Int>);
}

/** A second enum whose `Cont` holds the array directly. */
enum Single {
	Cont(values:Array<Int>);
}

class Main {
	/** The usual shape: a new array, `push` in a `while` loop, then return it. */
	public static function collect(count:Int):Array<Int> {
		var items = [];
		var i = 0;
		while (i < count) {
			items.push(i);
			i++;
		}
		return items;
	}

	/** `while (true)` with `break`, and `continue` for the values that are skipped. */
	public static function collectOdd(count:Int):Array<Int> {
		var items:Array<Int> = [];
		var i = 0;
		while (true) {
			if (i >= count)
				break;
			i++;
			if (i % 2 == 0)
				continue;
			items.push(i);
		}
		return items;
	}

	/**
	 * A parser shape: `return` inside the loop reads the array, and a second
	 * `return` leaves without it.
	 */
	public static function untilLimit(count:Int, limit:Int):String {
		var items = [];
		var i = 0;
		while (true) {
			if (i > limit)
				return "over:" + i;
			items.push(i * 3);
			i++;
			if (i == count)
				return "done:" + items.length + ":" + items[items.length - 1];
		}
	}

	/** `for` over a range: one `push` for each value. */
	public static function squares(count:Int):Array<Int> {
		var items = [];
		for (i in 0...count)
			items.push(i * i);
		return items;
	}

	/** `for` over an array with a `push` that depends on a condition. */
	public static function keepEven(source:Array<Int>):Array<Int> {
		var kept = [];
		for (value in source) {
			if (value % 2 == 0)
				kept.push(value);
		}
		return kept;
	}

	/** Two arrays filled in one loop. */
	public static function split(count:Int):String {
		var low = [];
		var high = [];
		var i = 0;
		while (i < count) {
			if (i < count / 2)
				low.push(i);
			else
				high.push(i);
			i++;
		}
		return low.join(",") + "|" + high.join(",");
	}

	/** Reads `length` and the last item while it pushes. */
	public static function runningTotal(count:Int):Int {
		var items = [];
		var total = 0;
		var i = 0;
		while (i < count) {
			items.push(i);
			total += items.length + items[items.length - 1];
			i++;
		}
		return total;
	}

	/** Starts from an array that already holds items. */
	public static function extend(count:Int):Array<Int> {
		var items = [100, 200];
		var i = 0;
		while (i < count) {
			items.push(i);
			i++;
		}
		return items;
	}

	/** Two loops push to one array, with a `push` between them. */
	public static function twoLoops(count:Int):Array<Int> {
		var items = [];
		var i = 0;
		while (i < count) {
			items.push(i);
			i++;
		}
		items.push(-1);
		while (i > 0) {
			i--;
			items.push(i);
		}
		return items;
	}

	/** A nested loop pushes to the array of the outer loop, and builds its own row. */
	public static function grid(rows:Int, columns:Int):String {
		var all = [];
		var lines = [];
		var row = 0;
		while (row < rows) {
			var cells = [];
			var column = 0;
			while (column < columns) {
				cells.push(row * columns + column);
				all.push(column);
				column++;
			}
			lines.push(cells.join(" "));
			row++;
		}
		return lines.join("/") + "|" + all.join("");
	}

	/** Pushes to an array that the caller passed in, and returns it. */
	public static function fill(target:Array<Int>, count:Int):Array<Int> {
		var i = 0;
		while (i < count) {
			target.push(i);
			i++;
		}
		return target;
	}

	/** A second name for the array, made after the loop, sees every item. */
	public static function aliasAfter(count:Int):String {
		var items = [];
		var i = 0;
		while (i < count) {
			items.push(i);
			i++;
		}
		var same = items;
		return same.length + ":" + items.length + ":" + same.join(",");
	}

	/** The pushed value reads another array built before the loop. */
	public static function doubled(source:Array<Int>):Array<Int> {
		var items = [];
		var i = 0;
		while (i < source.length) {
			items.push(source[i] * 2);
			i++;
		}
		return items;
	}

	/** Nothing is pushed: the result is the empty array. */
	public static function none():Array<Int> {
		var items = [];
		var i = 5;
		while (i < 3) {
			items.push(i);
			i++;
		}
		return items;
	}

	static function joined(values:Array<Int>):String {
		return values.join(",");
	}

	static function describe(step:Single):String {
		return switch (step) {
			case Cont(values): values.join(",");
		}
	}

	static function describeStep(step:Step):String {
		return switch (step) {
			case Cont(Box(values)): values.join("");
			case Plain(values): "plain" + values.join("");
		}
	}

	/** An assignment used as a value: `snap` must get the array in order. */
	public static function assignValue(count:Int):String {
		var items = [];
		var snap = [];
		var i = 0;
		while (i < count) {
			snap = (items = items.concat([i]));
			i++;
		}
		return snap.join(",") + "|" + items.join(",");
	}

	/** An assignment as a call argument in a `for` loop. */
	public static function assignArgumentFor(count:Int):String {
		var items = [];
		var seen = "";
		for (i in 0...count) {
			seen += joined(items = items.concat([i])) + ";";
		}
		return seen + "|" + items.join(",");
	}

	static function note(values:Array<Int>):Void {
		Sys.println("note " + values.join(","));
	}

	static function noteStep(step:Single):Void {
		switch (step) {
			case Cont(values):
				Sys.println("noteStep " + values.join(","));
		}
	}

	/**
	 * An assignment as the only statement of a `for` loop: a call argument.
	 * `note` prints what it gets, and `runtime.exs` reads that output.
	 */
	public static function assignOnlyFor(count:Int):String {
		var items = [];
		for (i in 0...count)
			note(items = items.concat([i]));
		return items.join(",");
	}

	/** `Cont(items)` passed to a function while a `for` loop pushes. */
	public static function contOnlyFor(count:Int):String {
		var items = [];
		for (i in 0...count) {
			items.push(i);
			noteStep(Single.Cont(items));
		}
		return items.join(",");
	}

	/** An assignment as a call argument in a `while` loop. */
	public static function assignArgumentWhile(count:Int):String {
		var items = [];
		var seen = "";
		var i = 0;
		while (i < count) {
			seen += joined(items = items.concat([i])) + ";";
			i++;
		}
		return seen + "|" + items.join(",");
	}

	/** The array inside `Cont(Box(items))` while a `while` loop pushes. */
	public static function contBox(count:Int):String {
		var seen = "";
		var items = [];
		var i = 0;
		while (i < count) {
			items.push(i);
			seen += describeStep(Step.Cont(Box(items))) + ";";
			i++;
		}
		return seen;
	}

	/** The array inside `Cont(items)` as a call argument while a `for` loop pushes. */
	public static function contArgument(count:Int):String {
		var items = [];
		var seen = "";
		for (i in 0...count) {
			items.push(i);
			seen += describe(Single.Cont(items)) + ";";
		}
		return seen + "|" + items.join(",");
	}

	static function line(label:String, result:String):Void {
		Sys.println(label + " " + result);
	}

	/**
	 * Prints the Haxe interpreter results kept in `interpreter.txt`:
	 * `haxe -cp . -main Main --interp > interpreter.txt`.
	 */
	public static function main():Void {
		line("collect", collect(5).join(","));
		line("collectOdd", collectOdd(9).join(","));
		line("untilLimit-done", untilLimit(4, 10));
		line("untilLimit-over", untilLimit(40, 2));
		line("squares", squares(5).join(","));
		line("keepEven", keepEven([4, 7, 10, 3, 8]).join(","));
		line("split", split(6));
		line("runningTotal", "" + runningTotal(6));
		line("extend", extend(3).join(","));
		line("twoLoops", twoLoops(3).join(","));
		line("grid", grid(2, 3));
		line("fill", fill([9, 8], 3).join(","));
		line("aliasAfter", aliasAfter(4));
		line("doubled", doubled([1, 2, 3]).join(","));
		line("none", "[" + none().join(",") + "]");
		line("assignValue", assignValue(4));
		line("assignArgumentFor", assignArgumentFor(4));
		line("assignArgumentWhile", assignArgumentWhile(4));
		line("contBox", contBox(4));
		line("contArgument", contArgument(3));
		line("assignOnlyFor", assignOnlyFor(3));
		line("contOnlyFor", contOnlyFor(3));
	}
}
