class TestInjectionDebug {
    static function main() {
        // This works - assigned to variable
        var x = untyped __elixir__('IO.puts("WORKS")');
        
        // This breaks - standalone statement
        untyped __elixir__('IO.puts("BREAKS")');
    }
}