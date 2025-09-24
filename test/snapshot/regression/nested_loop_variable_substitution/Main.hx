package;

/**
 * Test for nested loop variable substitution issue
 * When Haxe's optimizer replaces loop variables with literals,
 * they should be restored to the actual variable names
 */
class Main {
    static function main() {
        // Nested loop with string concatenation that triggers optimization
        for (i in 0...2) {
            for (j in 0...2) {
                trace('Cell (' + i + ',' + j + ')');
            }
        }
        
        // Single loop should also work
        for (k in 0...3) {
            trace('Index: ' + k);
        }
    }
}