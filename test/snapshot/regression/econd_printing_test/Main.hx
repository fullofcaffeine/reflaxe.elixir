package;

class Main {
    static function testCondPrinting(value: Int): String {
        // This will be transformed to use ECond in the guard grouping pass
        // For now, we're just testing that ECond nodes can be printed
        return if (value > 100) {
            "high";
        } else if (value > 50) {
            "medium";
        } else if (value > 0) {
            "low";
        } else {
            "zero or negative";
        }
    }
    
    static function main() {
        trace(testCondPrinting(75)); // Should print "medium"
    }
}