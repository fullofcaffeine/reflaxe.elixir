package helder;

import haxe.ds.StringMap;

/**
 * Minimal Set<T> implementation to satisfy genes generator dependencies.
 * Only supports constructor from iterable, add, and exists lookups used by genes.
 * Note: This is a lightweight compatibility shim, not a full-featured Set.
 */
class Set<T> {
  var map: StringMap<Bool>;

  public function new(?items: Iterable<T>) {
    map = new StringMap();
    if (items != null) for (item in items) add(item);
  }

  public function add(item: T): Void {
    map.set(Std.string(item), true);
  }

  public function exists(item: T): Bool {
    return map.exists(Std.string(item));
  }
}

