package;

class Main {
    static function main() {
        // Test 1: Expression context (assigned) - this works
        var assigned = untyped __elixir__('IO.puts("Expression context works")');
        
        // Test 2: Void context (statement) - this is broken
        untyped __elixir__('IO.puts("Void context broken")');
        
        /* AHA MOMENT: The traces reveal the REAL problem!
         * 
         * We DO get a TCall(TIdent("__elixir__"), [TConst(TString(...))])
         * The parent DirectToStringCompiler correctly detects this and returns the injected code
         * BUT somewhere in our compilation chain, we're RE-WRAPPING it in __elixir__()
         * 
         * The trace shows:
         * 1. Parent returns: "IO.puts(\"Void context broken\")" ✓ CORRECT
         * 2. Final output: __elixir__("IO.puts(\"Void context broken\")") ✗ WRONG!
         * 
         * So the injection IS working, but something is double-wrapping it.
         * This likely happens because:
         * - The parent processes TCall and returns the injection
         * - But we're in MethodCallCompiler which treats it as a regular call
         * - MethodCallCompiler wraps the function name + args, creating the double wrap
         */
    }
}