package;

/**
 * Test for nested unrolled loops - these are particularly tricky
 */
class Main {
    static function main() {
        // Nested loop that might get partially unrolled
        for (i in 0...2) {
            for (j in 0...2) {
                trace('Cell (' + i + ',' + j + ')');
            }
        }
    }
}