/**
 * Test case specifically for reproducing the bare concatenation edge case
 * in deeply nested array comprehensions with constant ranges.
 * 
 * This should trigger the problematic pattern where Haxe generates:
 * g = g ++ [g = []
 * g ++ [0]    // <-- bare concatenation, invalid Elixir!
 * g ++ [1]    // <-- bare concatenation, invalid Elixir!
 * g]
 */
class TestBareConcatenation {
    static function main() {
        // This specific pattern causes deeply nested bare concatenations
        // when Haxe unrolls the constant ranges
        var deeplyNested = [for (i in 0...2) 
                              [for (j in 0...2) 
                                [for (k in 0...2) k]]];
        
        trace("Deeply nested with bare concatenations:");
        trace(deeplyNested);
        
        // Even deeper nesting to stress test the pattern
        var veryDeep = [for (a in 0...2)
                          [for (b in 0...2)
                            [for (c in 0...2)
                              [for (d in 0...2) d]]]];
        
        trace("Very deep nesting:");
        trace(veryDeep);
        
        // Mixed case: constant outer, variable inner
        var n = 2;
        var mixed = [for (i in 0...2)
                       [for (j in 0...n) j]];
        
        trace("Mixed constant/variable:");
        trace(mixed);
    }
}