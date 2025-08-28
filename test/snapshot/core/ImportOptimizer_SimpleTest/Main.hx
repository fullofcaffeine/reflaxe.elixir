package;

using StringTools;

/**
 * Test ImportOptimizer functionality.
 * This test should generate Elixir imports for detected function usage.
 */
class Main {
    public static function main() {
        // Test code that should generate pipeline patterns and imports
        var items = [1, 2, 3, 4, 5];
        
        // Test sequential operations that should be optimized to pipelines
        var result = [];
        result = items;
        result = result.filter(x -> x > 2);
        result = result.map(x -> x * 2);
        
        // Additional operations that should trigger imports
        var text = "hello world";
        text = text.trim();
        text = text.replace("world", "universe");
        
        trace('Result: ${result}');
        trace('Text: ${text}');
    }
}