/**
 * Example Haxe class that demonstrates basic Elixir compilation
 */
class Main {
    /**
     * Entry point - this will be compiled to an Elixir module
     */
    public static function main() {
        trace("Hello from Haxe compiled to Elixir!");
        
        // Demonstrate basic Haxe features that work in Elixir
        var numbers = [1, 2, 3, 4, 5];
        var sum = calculateSum(numbers);
        
        trace('Sum of ${numbers} = ${sum}');
        
        // Demonstrate string operations
        var message = "Reflaxe.Elixir";
        var processed = processMessage(message);
        trace('Processed: ${processed}');
    }
    
    /**
     * Calculate sum of an array
     */
    static function calculateSum(numbers: Array<Int>): Int {
        var total = 0;
        for (num in numbers) {
            total += num;
        }
        return total;
    }
    
    /**
     * Process a message string
     */
    static function processMessage(message: String): String {
        return message.toLowerCase() + " is awesome!";
    }
}