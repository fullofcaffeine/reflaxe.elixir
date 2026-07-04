package haxe.ds;

/**
 * ListSort (Elixir target) - explicit unsupported runtime surface.
 *
 * WHAT
 * - Preserves the upstream static method signatures so code type-checks far
 *   enough for the Elixir backend to issue a clear diagnostic.
 *
 * WHY
 * - Upstream `ListSort` mutates arbitrary linked-node `next`/`prev` fields in
 *   place. Ordinary BEAM structs and maps are immutable values, so lowering
 *   that API silently would produce misleading code.
 *
 * HOW
 * - Macro/eval contexts keep a small Haxe implementation for tooling.
 * - Runtime calls are extern and are rejected by `CallExprBuilder` with an
 *   actionable target diagnostic.
 */
#if macro
class ListSort {
	public static function sort<T:{prev:T, next:T}>(list:T, cmp:T->T->Int):T {
		return sortSingleLinked(list, cmp);
	}

	public static function sortSingleLinked<T:{next:T}>(list:T, cmp:T->T->Int):T {
		if (list == null)
			return null;

		var nodes:Array<T> = [];
		var current = list;
		while (current != null) {
			nodes.push(current);
			current = current.next;
		}

		ArraySort.sort(nodes, cmp);
		for (i in 0...nodes.length) {
			nodes[i].next = i == nodes.length - 1 ? null : nodes[i + 1];
		}

		return nodes.length == 0 ? null : nodes[0];
	}
}
#else
@:nativeGen
extern class ListSort {
	public static function sort<T:{prev:T, next:T}>(list:T, cmp:T->T->Int):T;
	public static function sortSingleLinked<T:{next:T}>(list:T, cmp:T->T->Int):T;
}
#end
