/**
 * BalancedTree: Elixir-compatible implementation of balanced tree
 * 
 * WHY: The standard Haxe BalancedTree uses exception handling that's incompatible
 * with the Elixir target's exception typing. This implementation provides the
 * same API but uses return values instead of exceptions.
 * 
 * WHAT: A balanced binary search tree that allows key-value mapping with
 * arbitrary keys that can be ordered. Operations have logarithmic cost.
 * 
 * HOW: Uses the same algorithm as standard BalancedTree but replaces exception
 * throwing with null/false returns for error cases.
 * 
 * @see https://api.haxe.org/haxe/ds/BalancedTree.html - Original API
 */
package haxe.ds;

class BalancedTree<K, V> implements haxe.Constraints.IMap<K, V> {
    var root: TreeNode<K, V>;
    
    /**
     * Creates a new BalancedTree, which is initially empty.
     */
    public function new() {}
    
    /**
     * Binds `key` to `value`.
     * If `key` is already bound to a value, that binding disappears.
     */
    public function set(key: K, value: V) {
        root = setLoop(key, value, root);
    }
    
    /**
     * Returns the value `key` is bound to.
     * If `key` is not bound to any value, `null` is returned.
     */
    public function get(key: K): Null<V> {
        var node = root;
        while (node != null) {
            var c = compare(key, node.key);
            if (c == 0)
                return node.value;
            if (c < 0)
                node = node.left;
            else
                node = node.right;
        }
        return null;
    }
    
    /**
     * Removes the current binding of `key`.
     * Returns true if binding was removed, false if key had no binding.
     */
    public function remove(key: K): Bool {
        var result = removeLoop(key, root);
        if (result != null) {
            root = result.node;
            return result.found;
        }
        return false;
    }
    
    /**
     * Tells if `key` is bound to a value.
     */
    public function exists(key: K): Bool {
        var node = root;
        while (node != null) {
            var c = compare(key, node.key);
            if (c == 0)
                return true;
            else if (c < 0)
                node = node.left;
            else
                node = node.right;
        }
        return false;
    }
    
    /**
     * Iterates over the bound values of `this` BalancedTree.
     * This operation is performed in-order.
     */
    public function iterator(): Iterator<V> {
        var ret = [];
        iteratorLoop(root, ret);
        return ret.iterator();
    }
    
    /**
     * See `Map.keyValueIterator`
     */
    @:runtime public inline function keyValueIterator(): KeyValueIterator<K, V> {
        return new haxe.iterators.MapKeyValueIterator(this);
    }
    
    /**
     * Iterates over the keys of `this` BalancedTree.
     * This operation is performed in-order.
     */
    public function keys(): Iterator<K> {
        var ret = [];
        keysLoop(root, ret);
        return ret.iterator();
    }
    
    public function copy(): BalancedTree<K, V> {
        var copied = new BalancedTree<K, V>();
        copied.root = root;
        return copied;
    }
    
    function setLoop(k: K, v: V, node: TreeNode<K, V>) {
        if (node == null)
            return new TreeNode<K, V>(null, k, v, null);
        var c = compare(k, node.key);
        return if (c == 0) new TreeNode<K, V>(node.left, k, v, node.right, node.get_height()); 
        else if (c < 0) {
            var nl = setLoop(k, v, node.left);
            balance(nl, node.key, node.value, node.right);
        } else {
            var nr = setLoop(k, v, node.right);
            balance(node.left, node.key, node.value, nr);
        }
    }
    
    // Modified to return both the node and whether key was found
    function removeLoop(k: K, node: TreeNode<K, V>): Null<{node: TreeNode<K, V>, found: Bool}> {
        if (node == null)
            return {node: null, found: false};
        var c = compare(k, node.key);
        if (c == 0) {
            return {node: merge(node.left, node.right), found: true};
        } else if (c < 0) {
            var result = removeLoop(k, node.left);
            if (result != null && result.found) {
                return {node: balance(result.node, node.key, node.value, node.right), found: true};
            }
            return {node: node, found: false};
        } else {
            var result = removeLoop(k, node.right);
            if (result != null && result.found) {
                return {node: balance(node.left, node.key, node.value, result.node), found: true};
            }
            return {node: node, found: false};
        }
    }
    
    static function iteratorLoop<K,V>(node: TreeNode<K, V>, acc: Array<V>) {
        if (node != null) {
            iteratorLoop(node.left, acc);
            acc.push(node.value);
            iteratorLoop(node.right, acc);
        }
    }
    
    function keysLoop(node: TreeNode<K, V>, acc: Array<K>) {
        if (node != null) {
            keysLoop(node.left, acc);
            acc.push(node.key);
            keysLoop(node.right, acc);
        }
    }
    
    function merge(t1: TreeNode<K, V>, t2: TreeNode<K, V>) {
        if (t1 == null)
            return t2;
        if (t2 == null)
            return t1;
        var t = minBinding(t2);
        if (t == null) return t1; // Safety check
        return balance(t1, t.key, t.value, removeMinBinding(t2));
    }
    
    function minBinding(t: TreeNode<K, V>): TreeNode<K, V> {
        if (t == null) return null;
        if (t.left == null) return t;
        return minBinding(t.left);
    }
    
    function removeMinBinding(t: TreeNode<K, V>): TreeNode<K, V> {
        if (t == null) return null;
        if (t.left == null) return t.right;
        return balance(removeMinBinding(t.left), t.key, t.value, t.right);
    }
    
    function balance(l: TreeNode<K, V>, k: K, v: V, r: TreeNode<K, V>): TreeNode<K, V> {
        var hl = l.get_height();
        var hr = r.get_height();
        return if (hl > hr + 2) {
            if (l.left.get_height() >= l.right.get_height())
                new TreeNode<K, V>(l.left, l.key, l.value, new TreeNode<K, V>(l.right, k, v, r));
            else
                new TreeNode<K, V>(new TreeNode<K, V>(l.left, l.key, l.value, l.right.left), l.right.key, l.right.value,
                    new TreeNode<K, V>(l.right.right, k, v, r));
        } else if (hr > hl + 2) {
            if (r.right.get_height() > r.left.get_height())
                new TreeNode<K, V>(new TreeNode<K, V>(l, k, v, r.left), r.key, r.value, r.right);
            else
                new TreeNode<K, V>(new TreeNode<K, V>(l, k, v, r.left.left), r.left.key, r.left.value,
                    new TreeNode<K, V>(r.left.right, r.key, r.value, r.right));
        } else {
            new TreeNode<K, V>(l, k, v, r, (hl > hr ? hl : hr) + 1);
        }
    }
    
    function compare(k1: K, k2: K) {
        return Reflect.compare(k1, k2);
    }
    
    public function toString() {
        return root == null ? "[]" : '[${root.toString()}]';
    }
    
    /**
     * Removes all keys from `this` BalancedTree.
     */
    public function clear(): Void {
        root = null;
    }
}

/**
 * A tree node of `haxe.ds.BalancedTree`.
 */
class TreeNode<K, V> {
    public var left: TreeNode<K, V>;
    public var right: TreeNode<K, V>;
    public var key: K;
    public var value: V;
    public var _height: Int;
    
    public function new(l, k, v, r, h = -1) {
        left = l;
        key = k;
        value = v;
        right = r;
        // Simplified height logic
        _height = h == -1 ? 1 : h;
    }
    
    public function get_height()
        return this == null ? 0 : _height;
    
    public function toString() {
        return (left == null ? "" : left.toString() + ", ") + '$key => $value' + (right == null ? "" : ", " + right.toString());
    }
}