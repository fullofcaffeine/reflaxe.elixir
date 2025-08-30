// Test target code injection
class TestInjection {
    public static function main() {
        // Test 1: Direct __elixir__ injection
        var result1 = untyped __elixir__('IO.puts("Direct injection test")');
        
        // Test 2: Injection with parameters
        var name = "World";
        var result2 = untyped __elixir__('IO.puts("Hello, {0}!")', name);
        
        // Test 3: Inline function with injection
        testInline();
    }
    
    public static inline function testInline() {
        // This should be inlined at the call site
        return untyped __elixir__('IO.puts("Inline injection test")');
    }
}