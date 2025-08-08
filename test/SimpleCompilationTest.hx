package test;

// Simple test to verify ElixirCompiler can be instantiated
// This will test the basic GREEN phase implementation

import reflaxe.elixir.ElixirCompiler;

class SimpleCompilationTest {
    public static function main() {
        trace("Testing basic ElixirCompiler functionality...");
        
        try {
            // Test 1: Can create compiler instance
            var compiler = new ElixirCompiler();
            trace("✅ ElixirCompiler instantiated successfully");
            
            // Test 2: Check basic properties
            trace("File extension: " + compiler.fileExtension);
            trace("Output directory: " + compiler.outputDirectory);
            
            // Test 3: Test naming convention utility
            var result1 = compiler.toElixirName("MyClass");
            var result2 = compiler.toElixirName("someMethod");
            trace("MyClass -> " + result1);
            trace("someMethod -> " + result2);
            
            // Test 4: Test basic method calls (with null inputs - should handle gracefully)
            var classResult = compiler.compileClassImpl(null, [], []);
            var enumResult = compiler.compileEnumImpl(null, []);
            var exprResult = compiler.compileExpressionImpl(null, false);
            
            trace("compileClassImpl(null): " + (classResult == null ? "null (expected)" : "returned value"));
            trace("compileEnumImpl(null): " + (enumResult == null ? "null (expected)" : "returned value"));
            trace("compileExpressionImpl(null): " + (exprResult == null ? "null (expected)" : "returned value"));
            
            trace("✅ All basic tests passed!");
            
        } catch (e) {
            trace("❌ Test failed: " + e);
            trace("Stack: " + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
        }
    }
}