/**
 * Test __elixir__ code injection mechanism
 * 
 * Tests that untyped __elixir__() calls are properly handled by 
 * Reflaxe's targetCodeInjectionName mechanism and generate clean
 * Elixir code without wrappers.
 */
class Main {
    public static function main() {
        testSimpleInjection();
        testInjectionWithParameters();
        testInjectionWithReturn();
        testInlineInjection();
    }
    
    static function testSimpleInjection() {
        // Simple injection without parameters
        untyped __elixir__("IO.puts(\"Simple injection test\")");
    }
    
    static function testInjectionWithParameters() {
        // Injection with parameter substitution
        var name = "World";
        var count = 42;
        untyped __elixir__("IO.puts(\"Hello {0}, count: {1}\")", name, count);
    }
    
    static function testInjectionWithReturn() {
        // Injection that returns a value
        var now = untyped __elixir__("DateTime.utc_now()");
        
        // Use injected value
        untyped __elixir__("IO.inspect({0})", now);
    }
    
    static inline function injectCode(msg: String) {
        // Inline function with injection
        return untyped __elixir__("IO.puts({0})", msg);
    }
    
    static function testInlineInjection() {
        // Test that inline functions with injection work
        injectCode("Inline injection test");
    }
}