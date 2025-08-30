// Let's add tracing to understand what AST we're getting
class TraceAST {
    public static function main() {
        // This should trigger the injection
        test();
    }
    
    static function test() {
        // Using untyped should create TIdent("__elixir__")
        untyped __elixir__("IO.puts(\"test\")");
    }
}