// Force new compilation
class TraceAST2 {
    public static function main() {
        // This should trigger injection
        untyped __elixir__("IO.puts(\"TESTING INJECTION\")");
        
        // Test with parameter
        var x = "param";
        untyped __elixir__("IO.inspect({0})", x);
    }
}