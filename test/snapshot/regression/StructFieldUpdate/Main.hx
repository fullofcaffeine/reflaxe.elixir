package;

/**
 * Test for struct field update patterns
 * 
 * This test demonstrates how instance field assignments should be handled
 * in immutable Elixir. Since Elixir structs are immutable, assignments to
 * fields like `this.value = newValue` need special handling.
 */
class Main {
    static function main() {
        var tree = new SimpleTree(null);
        tree.set("key1", "value1");
        tree.set("key2", "value2");
        
        var value = tree.get("key1");
        trace(value); // Should output "value1"
    }
}

// Simple tree structure to test field updates
class SimpleTree<V> {
    public var root: TreeNode<V>;
    
    public function new(root: TreeNode<V>) {
        this.root = root;
    }
    
    public function set(key: String, value: V): Void {
        // This assignment should not generate "unused variable" warning
        // In Elixir, this needs to become a struct update pattern
        root = insertNode(root, key, value);
    }
    
    public function get(key: String): Null<V> {
        return findNode(root, key);
    }
    
    private function insertNode(node: TreeNode<V>, key: String, value: V): TreeNode<V> {
        if (node == null) {
            return new TreeNode(key, value, null, null);
        }
        
        if (key < node.key) {
            return new TreeNode(node.key, node.value, insertNode(node.left, key, value), node.right);
        } else if (key > node.key) {
            return new TreeNode(node.key, node.value, node.left, insertNode(node.right, key, value));
        } else {
            // Key exists, update value
            return new TreeNode(key, value, node.left, node.right);
        }
    }
    
    private function findNode(node: TreeNode<V>, key: String): Null<V> {
        if (node == null) return null;
        
        if (key < node.key) {
            return findNode(node.left, key);
        } else if (key > node.key) {
            return findNode(node.right, key);
        } else {
            return node.value;
        }
    }
}

class TreeNode<V> {
    public var key: String;
    public var value: V;
    public var left: TreeNode<V>;
    public var right: TreeNode<V>;
    
    public function new(key: String, value: V, left: TreeNode<V>, right: TreeNode<V>) {
        this.key = key;
        this.value = value;
        this.left = left;
        this.right = right;
    }
}