package;

class Main {
    static function main() {
        // Test basic __elixir__() injection
        var result = untyped __elixir__('IO.puts("Hello from Elixir!")');
        
        // Test with expression evaluation
        var sum = untyped __elixir__('1 + 2 + 3');
        
        // Test with Elixir-specific syntax (pipe operator)
        var piped = untyped __elixir__('[1, 2, 3] |> Enum.map(&(&1 * 2))');
        
        // Test with multiline Elixir code
        var multiline = untyped __elixir__('
            x = 10
            y = 20
            x + y
        ');
        
        // Test within a function
        testInjectionInFunction();
    }
    
    static function testInjectionInFunction(): Void {
        // Test __elixir__() within a function body
        untyped __elixir__('Logger.info("Injection works in functions!")');
        
        // Test with simple Elixir expression
        untyped __elixir__('IO.puts("Hello from function!")');
    }
}