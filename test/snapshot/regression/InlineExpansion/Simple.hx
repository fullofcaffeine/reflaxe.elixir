/**
 * Simplified test for inline expansion in binary operations
 */
class Node {
    public var value: Int;
    
    public function new() {
        value = 5;
    }
    
    extern public inline function getValue()
        return this == null ? 0 : value;
}

class Simple {
    static function test() {
        var a = new Node();
        var b = new Node();
        
        // Single inline expansion (should work)
        var single = a.getValue();
        trace("Single: " + single);
        
        // Binary operation with two inline expansions (problematic)
        var comparison = a.getValue() >= b.getValue();
        trace("Comparison: " + comparison);
        
        // If condition with binary operation of inline expansions (most problematic)
        if (a.getValue() >= b.getValue()) {
            trace("a >= b");
        }
    }
    
    static function main() {
        test();
    }
}