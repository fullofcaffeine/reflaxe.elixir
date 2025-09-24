class Main {
    public static function main() {
        // Test bracket notation detection with nested loops
        for (x in 0...2) {
            for (y in 0...2) {
                trace('Grid[${x}][${y}]');
            }
        }
        
        // Test mixed notation (parentheses and brackets)
        for (i in 0...3) {
            for (j in 0...3) {
                trace('Cell(${i}, ${j}) and Grid[${i}][${j}]');
            }
        }
        
        // Test 3D bracket notation
        for (x in 0...2) {
            for (y in 0...2) {
                for (z in 0...2) {
                    trace('Cube[${x}][${y}][${z}]');
                }
            }
        }
    }
}