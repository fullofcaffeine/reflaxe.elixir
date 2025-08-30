package;

class TestInject {
    public static function main() {
        // Test basic __elixir__ injection
        var result = untyped __elixir__('IO.puts("Hello from Elixir!")');
        
        // Test injection with parameters
        var x = 42;
        var y = "world";
        var computed = untyped __elixir__('IO.inspect({0} + 10)', x);
        var formatted = untyped __elixir__('"Hello, {0}!"', y);
        
        // Test more complex injection
        var list = [1, 2, 3];
        var mapped = untyped __elixir__('Enum.map({0}, fn x -> x * 2 end)', list);
        
        // Test injection in function context
        testInjectionInFunction();
    }
    
    static function testInjectionInFunction() {
        var name = "Elixir";
        // Direct Elixir code for IO operations
        untyped __elixir__('IO.puts("Testing injection in function with name: {0}")', name);
        
        // Using Elixir's pattern matching directly
        var result = untyped __elixir__('
            case {0} of
              "Elixir" -> :ok
              _ -> :error
            end
        ', name);
    }
}