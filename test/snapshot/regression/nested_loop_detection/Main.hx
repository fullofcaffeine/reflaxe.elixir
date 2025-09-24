package;

/**
 * Test for nested loop detection in unrolled patterns
 * 
 * When Haxe unrolls nested loops, it generates:
 * trace("Cell (0,0)")
 * trace("Cell (0,1)")  
 * trace("Cell (1,0)")
 * trace("Cell (1,1)")
 * 
 * We need to detect this is a 2x2 nested loop, not 4 separate statements
 */
class Main {
    static function main() {
        // Simple 2x2 nested loop
        for (i in 0...2) {
            for (j in 0...2) {
                trace('Cell ($i,$j)');
            }
        }
        
        // 3x3 nested loop  
        for (x in 0...3) {
            for (y in 0...3) {
                trace('Grid [$x][$y]');
            }
        }
        
        // Triple nested (should not be unrolled by Haxe)
        for (i in 0...2) {
            for (j in 0...2) {
                for (k in 0...2) {
                    trace('3D ($i,$j,$k)');
                }
            }
        }
    }
}