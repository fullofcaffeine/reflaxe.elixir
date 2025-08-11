
/**
 * BasicModule - Demonstrates core @:module syntax
 * 
 * This example shows the most basic usage of @:module annotation
 * to eliminate boilerplate "public static" declarations while
 * maintaining Haxe's type safety.
 */
@:module
class BasicModule {
    
    /**
     * Simple greeting function
     * Compiles to: def hello(), do: "world"
     */
    function hello(): String {
        return "world";
    }
    
    /**
     * Function with parameters
     * Compiles to: def greet(name), do: "Hello, #{name}!"
     */
    function greet(name: String): String {
        return "Hello, " + name + "!";
    }
    
    /**
     * Function with multiple parameters and logic
     * Demonstrates that complex logic compiles correctly
     */
    function calculate(x: Int, y: Int, operation: String): Int {
        return switch (operation) {
            case "add": x + y;
            case "subtract": x - y;
            case "multiply": x * y;
            case "divide": y != 0 ? Std.int(x / y) : 0;
            case _: 0;
        };
    }
    
    /**
     * Function with no parameters
     * Compiles to: def get_timestamp(), do: DateTime.utc_now()
     */
    function getTimestamp(): String {
        return "2024-01-01T00:00:00Z";
    }
    
    /**
     * Boolean function demonstrating predicate patterns
     * Common in Elixir for validation and guards
     */
    function isValid(input: String): Bool {
        return input != null && input.length > 0;
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("BasicModule example compiled successfully!");
    }
}