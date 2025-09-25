package;

/**
 * Test for loop behavior WITHOUT analyzer-optimize
 * This should generate correct output even without our fixes
 * because the Haxe optimizer doesn't interfere
 */
class Main {
    static function main() {
        // Same nested loop as in the optimizer test
        for (i in 0...2) {
            for (j in 0...2) {
                trace('Cell (' + i + ',' + j + ')');
            }
        }
        
        // Same simple loop as in the optimizer test
        for (k in 0...3) {
            trace('Index: ' + k);
        }
    }
}