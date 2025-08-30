import elixir.Injection;

// Test if typed __elixir__ works better than untyped
class TestTypedInjection {
    public static function main() {
        // Test 1: Typed call to __elixir__ (no untyped)
        var result1 = Injection.__elixir__('IO.puts("Typed injection test")');
        
        // Test 2: With parameters
        var name = "World";
        var result2 = Injection.__elixir__('IO.puts("Hello, {0}!")', name);
        
        // Test 3: Compare with untyped
        var result3 = untyped __elixir__('IO.puts("Untyped injection test")');
    }
}