package haxe.ds;

/**
 * BalancedTree (Elixir target) — bootstrap-safe override
 *
 * This module exists because Haxe compilation has **two phases**:
 *
 * 1) **Macro / eval phase** (host-side):
 *    - Haxe executes macros using the `eval` interpreter.
 *    - In that phase, classes can be instantiated and their constructors must exist.
 *
 * 2) **Target compilation phase** (Elixir output):
 *    - The same compilation also needs `haxe.ds.BalancedTree` to exist as a type.
 *    - However, the canonical Haxe stdlib implementation is not a good fit for BEAM and can
 *      produce Elixir warnings that fail CI under `--warnings-as-errors` (WAE).
 *
 * To satisfy both phases, this file is **dual-mode**:
 *
 * - `#if macro`: provides a small, correct, in-memory implementation (so eval/macros work).
 * - `#else`: provides an `@:nativeGen extern` surface (so Elixir codegen does not emit the
 *   canonical stdlib implementation into generated `.ex` files).
 *
 * Why `src/`?
 * - `src/` is the only path guaranteed to be available immediately when a project uses
 *   `-lib reflaxe.elixir` (haxelib installs use `classPath: "src"`).
 * - Relying purely on macro-time classpath injection can be non-deterministic because some
 *   stdlib modules are resolved/cached before bootstrap macros run.
 */
#if macro
class BalancedTree<K, V> implements haxe.Constraints.IMap<K, V> {
	public var root:TreeNode<K, V>;

	var pairs:Array<{key:K, value:V}>;

	#if (haxe_ver >= 5)
	public function size():Int {
		return pairs.length;
	}
	#end

	public function new() {
		pairs = [];
		root = null;
	}

	public function set(key:K, value:V):Void {
		var i = 0;
		while (i < pairs.length) {
			var kv = pairs[i];
			var d = compare(key, kv.key);
			if (d == 0) {
				pairs[i] = {key: kv.key, value: value};
				return;
			}
			if (d < 0) {
				pairs.insert(i, {key: key, value: value});
				return;
			}
			i += 1;
		}
		pairs.push({key: key, value: value});
	}

	public function get(key:K):Null<V> {
		for (kv in pairs) {
			if (compare(key, kv.key) == 0)
				return kv.value;
		}
		return null;
	}

	public function exists(key:K):Bool {
		for (kv in pairs) {
			if (compare(key, kv.key) == 0)
				return true;
		}
		return false;
	}

	public function remove(key:K):Bool {
		var i = 0;
		while (i < pairs.length) {
			if (compare(key, pairs[i].key) == 0) {
				pairs.splice(i, 1);
				return true;
			}
			i += 1;
		}
		return false;
	}

	public function iterator():Iterator<V> {
		var values = new Array<V>();
		for (kv in pairs)
			values.push(kv.value);
		return values.iterator();
	}

	public function keys():Iterator<K> {
		var keys = new Array<K>();
		for (kv in pairs)
			keys.push(kv.key);
		return keys.iterator();
	}

	public function keyValueIterator():KeyValueIterator<K, V> {
		return pairs.iterator();
	}

	public function copy():BalancedTree<K, V> {
		var copied = new BalancedTree<K, V>();
		copied.pairs = pairs.copy();
		return copied;
	}

	public function toString():String {
		return pairs.toString();
	}

	public function clear():Void {
		pairs = [];
		root = null;
	}

	function compare(k1:K, k2:K):Int {
		return Reflect.compare(k1, k2);
	}
}

class TreeNode<K, V> {
	public var left:TreeNode<K, V>;
	public var right:TreeNode<K, V>;
	public var key:K;
	public var value:V;

	public function new(l:TreeNode<K, V>, k:K, v:V, r:TreeNode<K, V>, ?h:Int) {
		left = l;
		key = k;
		value = v;
		right = r;
	}

	public function get_height():Int {
		return 0;
	}

	public function toString():String {
		return 'TreeNode(${Std.string(key)}, ${Std.string(value)})';
	}
}
#else
@:nativeGen
extern class BalancedTree<K, V> implements haxe.Constraints.IMap<K, V> {
	// Kept as a field to match stdlib subclasses (EnumValueMap.copy assigns it).
	public var root:TreeNode<K, V>;

	#if (haxe_ver >= 5)
	public function size():Int;
	#end

	public function new():Void;
	public function set(key:K, value:V):Void;
	public function get(key:K):Null<V>;
	public function exists(key:K):Bool;
	public function remove(key:K):Bool;
	public function iterator():Iterator<V>;
	public function keys():Iterator<K>;
	public function keyValueIterator():KeyValueIterator<K, V>;
	public function copy():BalancedTree<K, V>;
	public function toString():String;
	public function clear():Void;
	function compare(k1:K, k2:K):Int;
}

@:nativeGen
extern class TreeNode<K, V> {
	public var left:TreeNode<K, V>;
	public var right:TreeNode<K, V>;
	public var key:K;
	public var value:V;

	public function new(l:TreeNode<K, V>, k:K, v:V, r:TreeNode<K, V>, ?h:Int):Void;
	public function get_height():Int;
	public function toString():String;
}
#end
