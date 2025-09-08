/**
 * Test: Module with static main() but no external dependencies
 * Expected: Should generate bootstrap code (Main.main()) but no Code.require_file statements
 */
class Main {
    public static function main(): Void {
        // Simple computation with no external dependencies
        var x = 10;
        var y = 20;
        var result = x + y;
        
        // Direct IO.puts call (IO is built-in Elixir module)
        untyped __elixir__('IO.puts("Result: #{0}")', result);
    }
}