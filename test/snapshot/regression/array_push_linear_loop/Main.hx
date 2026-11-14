/**
 * `array.push` in a loop must take time in proportion to the number of items.
 *
 * `runtime.exs` calls these functions from Elixir. It compares the results
 * with the Haxe interpreter and collects 200,000 items with a time budget.
 */
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
	}
}
