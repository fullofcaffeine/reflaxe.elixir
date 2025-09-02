/**
 * Test for increment/decrement patterns in loops
 * This reproduces the issue seen in haxe.io.Input/Output where
 * expressions like pos++ and k-- are being generated as standalone
 * expressions instead of assignments
 */
class Main {
    static function main() {
        testWhileLoop();
        testForLoop();
    }
    
    static function testWhileLoop() {
        var k = 10;
        var pos = 0;
        
        while (k > 0) {
            trace('Processing at position: $pos');
            pos++;  // Should become: pos = pos + 1
            k--;    // Should become: k = k - 1
        }
        
        trace('Final: k=$k, pos=$pos');
    }
    
    static function testForLoop() {
        var count = 0;
        
        for (i in 0...5) {
            trace('Iteration: $i');
            count++;  // Should become: count = count + 1
        }
        
        trace('Total count: $count');
    }
    
    static function testComplexLoop() {
        var data = [1, 2, 3, 4, 5];
        var sum = 0;
        var i = 0;
        
        while (i < data.length) {
            sum += data[i];  // Should become: sum = sum + data[i]
            i++;             // Should become: i = i + 1
        }
        
        trace('Sum: $sum');
    }
}