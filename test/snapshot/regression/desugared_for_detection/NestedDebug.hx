class NestedDebug {
    static function main() {
        // Outer loop
        for (x in 0...3) {
            trace('Outer: $x');
            // Inner loop  
            for (y in 0...3) {
                trace('Inner: ($x, $y)');
            }
        }
    }
}