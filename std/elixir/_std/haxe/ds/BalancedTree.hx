package haxe.ds;

/**
 * Elixir target surface for the official Haxe balanced tree.
 *
 * The target runtime replaces this mutable tree with native BEAM collection
 * behavior. Macro/eval compilation uses `haxe/ds/BalancedTree.macro.hx`.
 */
@:nativeGen
extern class BalancedTree<K, V> implements haxe.Constraints.IMap<K, V> {
	// Keep this field because official subclasses assign it while copying.
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
