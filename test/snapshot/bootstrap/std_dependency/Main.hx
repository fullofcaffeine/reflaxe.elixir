/**
 * Test: Module with static main() that uses Std module
 * Expected: Should generate bootstrap code and Code.require_file("std.ex", __DIR__)
 */
class Main {
    public static function main(): Void {
        var numbers = [1, 2, 3, 4, 5];
        var text = Std.string(numbers);
        
        // Use untyped to directly output with IO.puts
        untyped __elixir__('IO.puts({0})', text);
    }
}