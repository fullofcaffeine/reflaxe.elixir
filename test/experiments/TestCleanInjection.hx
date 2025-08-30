// Fresh test for __elixir__ injection
class TestCleanInjection {
    public static function main() {
        // Test 1: Simple injection
        untyped __elixir__("IO.puts(\"Clean injection test\")");
        
        // Test 2: With parameter
        var msg = "Hello from injection";
        untyped __elixir__("IO.puts({0})", msg);
        
        // Test 3: With return value
        var result = untyped __elixir__("DateTime.utc_now()");
    }
}