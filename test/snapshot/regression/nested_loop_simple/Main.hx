package;

/**
 * Simple nested loop detection test
 * Tests that 2x2 nested loops are properly detected and transformed
 */
class Main {
    static function main() {
        // This should be detected as a 2x2 nested loop
        trace("Cell (0,0)");
        trace("Cell (0,1)");
        trace("Cell (1,0)");
        trace("Cell (1,1)");
    }
}