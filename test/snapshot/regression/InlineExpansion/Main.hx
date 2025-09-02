/**
 * Test for inline function expansion patterns.
 * 
 * This tests that inline functions that expand to complex
 * blocks are properly transformed into single expressions
 * when used in contexts that require expressions.
 */
class TreeNode<T> {
    public var _height: Int;
    public var left: TreeNode<T>;
    public var right: TreeNode<T>;
    
    public function new() {
        _height = 0;
    }
    
    // Inline function that creates a conditional with null check
    extern public inline function get_height()
        return this == null ? 0 : _height;
}

class Main {
    static function test() {
        var node = new TreeNode<Int>();
        var l = new TreeNode<Int>();
        var r = new TreeNode<Int>();
        
        // This triggers inline expansion in binary comparison context
        if (l.left.get_height() >= l.right.get_height()) {
            trace("left is taller or equal");
        }
        
        // Another complex inline usage in arithmetic
        var totalHeight = l.get_height() + r.get_height();
        trace("Total height: " + totalHeight);
        
        // In boolean context
        var hasHeight = l.get_height() > 0;
        trace("Has height: " + hasHeight);
    }
    
    static function main() {
        test();
    }
}