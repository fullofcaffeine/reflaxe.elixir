package haxe.ds;

/**
 * ArraySort (Elixir target) - bootstrap-safe stable sort surface.
 *
 * WHAT
 * - Keeps the upstream public API for local array bindings:
 *   `ArraySort.sort(array, cmp)` mutates the caller-visible local and returns
 *   `Void`.
 *
 * WHY
 * - The upstream implementation is an in-place recursive merge sort over
 *   indexed array assignment. On the BEAM target, arrays are persistent lists,
 *   so compiling that implementation is both noisy and the wrong runtime
 *   shape.
 *
 * HOW
 * - Macro/eval compilation gets a small pure-Haxe stable insertion sort.
 * - Runtime compilation exposes an extern surface. `CallExprBuilder` lowers
 *   `ArraySort.sort(localArray, cmp)` to a same-scope rebinding with
 *   `Enum.sort/2` and a `cmp(left, right) <= 0` wrapper, preserving stable
 *   equal-key ordering.
 * - Non-local array expressions fail fast because their mutating Haxe API
 *   cannot be faithfully represented without updating the containing value.
 *
 * EXAMPLE
 * ```haxe
 * ArraySort.sort(items, (a, b) -> a.rank - b.rank);
 * ```
 * emits target-native sorting roughly shaped as:
 * ```elixir
 * items = Enum.sort(items, fn left, right -> cmp.(left, right) <= 0 end)
 * ```
 */
#if macro
class ArraySort {
	static public function sort<T>(a:Array<T>, cmp:T->T->Int):Void {
		if (a == null || cmp == null)
			return;

		for (i in 1...a.length) {
			var value = a[i];
			var j = i;
			while (j > 0 && cmp(value, a[j - 1]) < 0) {
				a[j] = a[j - 1];
				j--;
			}
			a[j] = value;
		}
	}
}
#else
@:nativeGen
extern class ArraySort {
	static public function sort<T>(a:Array<T>, cmp:T->T->Int):Void;
}
#end
