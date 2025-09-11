package;

class TestSimple {
    static function main() {
        // Simplest possible nested comprehension with constants
        var x = [for (i in 0...2) [for (j in 0...2) j]];
        trace(x);
    }
}