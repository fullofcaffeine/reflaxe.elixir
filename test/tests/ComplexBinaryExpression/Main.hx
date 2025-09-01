/**
 * Test for complex binary expressions with assignments
 * This reproduces the issue seen in haxe.io.Bytes where expressions like:
 * c = c - 55232 <<< 10 ||| index = i + 1
 * are incorrectly split across multiple lines
 */
class Main {
    static function main() {
        testComplexAssignmentWithBinary();
        testMethodCallInBinaryExpression();
    }
    
    static function testComplexAssignmentWithBinary() {
        var c = 60000;
        var i = 0;
        var index = 0;
        
        // This pattern appears in Bytes.of_string
        // Should compile to single line: c = ((c - 55232) <<< 10) ||| (index = i + 1)
        c = c - 55232 << 10 | (index = i + 1);
        
        trace('c: $c, index: $index');
    }
    
    static function testMethodCallInBinaryExpression() {
        var s = new TestString("test");
        var i = 0;
        var index = 0;
        var c = 0;
        
        // Pattern 1: Assignment with method call
        // Should be: c = s.cca(index = i + 1)
        c = s.cca(index = i + 1);
        
        // Pattern 2: Complex binary with method call  
        // Should be: c = ((c - 55232) <<< 10) ||| (s.cca(index = i + 1) &&& 1023)
        if (c > 55296) {
            c = (c - 55232) << 10 | (s.cca(index = i + 1) & 1023);
        }
        
        trace('final c: $c');
    }
}

class TestString {
    var str: String;
    
    public function new(s: String) {
        str = s;
    }
    
    public function cca(index: Int): Int {
        return if (index < str.length) str.charCodeAt(index) else 0;
    }
}