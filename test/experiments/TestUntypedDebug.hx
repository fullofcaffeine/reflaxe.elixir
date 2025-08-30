// Test to debug how untyped expressions are handled
class TestUntypedDebug {
    public static function main() {
        // Test various untyped forms
        
        // Form 1: untyped with direct call
        untyped __elixir__("IO.puts(\"Test 1\")");
        
        // Form 2: assignment of untyped result  
        var result = untyped __elixir__("IO.puts(\"Test 2\")");
        
        // Form 3: untyped with parameters
        var msg = "Test 3";
        untyped __elixir__("IO.puts({0})", msg);
    }
}