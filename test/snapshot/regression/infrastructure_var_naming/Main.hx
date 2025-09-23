/**
 * Infrastructure Variable Naming Test
 * 
 * Tests that infrastructure variables (_g, _g1) used in loop desugaring
 * are properly tracked and initialized in reduce_while calls.
 * 
 * Bug: Variables are tracked with underscore prefix ("_g") but looked up
 * without it ("g") due to ElixirNaming.toVarName stripping the underscore.
 */
class Main {
    static function main() {
        testSimpleLoop();
        testStringIteration();
    }

    // Test 1: Simple counting loop with infrastructure var _g
    static function testSimpleLoop(): Void {
        for (i in 0...3) {
            trace(i);
        }
    }

    // Test 2: String iteration with infrastructure vars _g and _g1
    static function testStringIteration(): String {
        var input = "ABC";
        var result = "";
        
        for (i in 0...input.length) {
            var c = input.charAt(i);
            result += c;
        }
        
        return result;
    }
}