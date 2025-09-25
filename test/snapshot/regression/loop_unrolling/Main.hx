package;

/**
 * Test for simple loop unrolling issue
 * When Haxe's optimizer unrolls simple loops,
 * they should be kept as idiomatic Enum.each calls
 */
class Main {
    static function main() {
        // Simple loop that gets unrolled
        for (k in 0...3) {
            trace('Index: ' + k);
        }
        
        // Loop with calculation that gets unrolled
        for (n in 0...4) {
            var squared = n * n;
            trace('Square of ' + n + ' is ' + squared);
        }
        
        // Loop with conditional that might be unrolled
        for (x in 0...5) {
            if (x % 2 == 0) {
                trace('Even: ' + x);
            } else {
                trace('Odd: ' + x);
            }
        }
    }
}