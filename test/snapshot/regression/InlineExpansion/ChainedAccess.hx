/**
 * Test for inline expansion with chained field access
 */
class Node {
    public var value: Int;
    public var left: Node;
    public var right: Node;
    
    public function new() {
        value = 5;
    }
    
    extern public inline function getValue()
        return this == null ? 0 : value;
}

class ChainedAccess {
    static function test() {
        var root = new Node();
        root.left = new Node();
        root.right = new Node();
        
        // Chained access with inline expansion (problematic case)
        if (root.left.getValue() >= root.right.getValue()) {
            trace("left >= right");
        }
    }
    
    static function main() {
        test();
    }
}