package haxe.ds;

/** Host-side stable sort used when compiler macros execute on eval. */
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
