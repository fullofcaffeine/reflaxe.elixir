class TestElixirInjection {
    public static function main() {
        // Test 1: Direct __elixir__ call
        var result1 = untyped __elixir__('IO.puts("Hello from Elixir")');
        
        // Test 2: With variables
        var name = "World";
        var result2 = untyped __elixir__('IO.puts("Hello " <> $name)');
        
        // Test 3: Supervisor.start_link
        var children = [];
        var opts = '[strategy: :one_for_one]';
        var result3 = untyped __elixir__('Supervisor.start_link($children, $opts)');
    }
}