import elixir.Syntax;

// Test the new Syntax.code API
class TestSyntax {
    public static function main() {
        // Test 1: Simple code injection
        Syntax.code('IO.puts("Testing Syntax.code")');
        
        // Test 2: Code with parameters
        var name = "Elixir";
        Syntax.code('IO.puts("Hello from {0}!")', name);
        
        // Test 3: Expression with return value
        var result = Syntax.code('DateTime.utc_now()');
        
        // Test 4: Complex expression
        var items = [1, 2, 3];
        var doubled = Syntax.code('Enum.map({0}, fn x -> x * 2 end)', items);
    }
}