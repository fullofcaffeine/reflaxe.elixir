package;

/**
 * Test for complex string building in loops
 * Variables should be preserved in all string operations
 */
class Main {
    static function main() {
        // Building a string with loop variables
        var result = "";
        for (i in 0...5) {
            result += "Item " + i + ", ";
        }
        trace("List: " + result);
        
        // Complex string formatting
        for (x in 1...4) {
            for (y in 1...4) {
                var product = x * y;
                trace(x + " × " + y + " = " + product);
            }
        }
        
        // String building with conditionals
        for (n in 0...10) {
            var label = n < 5 ? "Small" : "Large";
            trace("Number " + n + " is " + label);
        }
        
        // Template-like string building
        var items = ["apple", "banana", "cherry"];
        for (idx in 0...items.length) {
            var item = items[idx];
            trace("• Item #" + (idx + 1) + ": " + item + " (" + item.length + " chars)");
        }
    }
}