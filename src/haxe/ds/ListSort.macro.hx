package haxe.ds;

/** Host-side linked-list sort used when compiler macros execute on eval. */
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
