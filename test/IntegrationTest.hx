package test;

// Integration test for ElixirCompiler - Testing Trophy focused

import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.NamingHelper;

class IntegrationTest {
    public static function main() {
        trace("Running ElixirCompiler Integration Tests...");
        
        testNamingConventions();
        testBasicCompilerSetup();
        testFileExtensionAndDirectory();
        testElixirCodeGeneration();
        
        trace("✅ All integration tests passed!");
    }
    
    /**
     * Test naming convention utilities work as expected
     */
    static function testNamingConventions() {
        trace("TEST: Naming conventions work correctly");
        
        // Test snake_case conversion
        assertEqual(NamingHelper.toSnakeCase("MyClass"), "my_class", "MyClass -> my_class");
        assertEqual(NamingHelper.toSnakeCase("someMethod"), "some_method", "someMethod -> some_method");
        assertEqual(NamingHelper.toSnakeCase("HTTPClient"), "h_t_t_p_client", "HTTPClient -> h_t_t_p_client");
        
        // Test CamelCase conversion
        assertEqual(NamingHelper.toCamelCase("my_class"), "MyClass", "my_class -> MyClass");
        assertEqual(NamingHelper.toCamelCase("some_method"), "SomeMethod", "some_method -> SomeMethod");
        
        // Test Elixir module names
        assertEqual(NamingHelper.getElixirModuleName("MyClass"), "MyClass", "Simple module name");
        assertEqual(NamingHelper.getElixirModuleName("com.example.MyClass"), "Com.Example.MyClass", "Nested module name");
        
        // Test Elixir function names
        assertEqual(NamingHelper.getElixirFunctionName("someMethod"), "some_method", "Function name conversion");
        assertEqual(NamingHelper.getElixirFunctionName("new"), "__struct__", "Constructor mapping");
        
        trace("✅ Naming conventions test passed");
    }
    
    /**
     * Test basic compiler instantiation and configuration
     */
    static function testBasicCompilerSetup() {
        trace("TEST: Basic compiler setup");
        
        var compiler = new ElixirCompiler();
        
        // Test configuration
        assertEqual(compiler.fileExtension, ".ex", "File extension should be .ex");
        assertEqual(compiler.outputDirectory, "lib/", "Output directory should be lib/");
        
        // Test naming utility integration
        assertEqual(compiler.toElixirName("MyClass"), "my_class", "Compiler naming utility works");
        
        trace("✅ Basic compiler setup test passed");
    }
    
    /**
     * Test file extension and output directory configuration
     */
    static function testFileExtensionAndDirectory() {
        trace("TEST: File extension and directory configuration");
        
        var compiler = new ElixirCompiler();
        
        // These should be properly configured for Elixir
        assertEqual(compiler.fileExtension, ".ex", "Should use .ex extension");
        assertEqual(compiler.outputDirectory, "lib/", "Should output to lib/ directory");
        
        trace("✅ File extension and directory test passed");
    }
    
    /**
     * Test actual Elixir code generation from method calls
     */
    static function testElixirCodeGeneration() {
        trace("TEST: Elixir code generation");
        
        var compiler = new ElixirCompiler();
        
        // Test null handling
        var nullClassResult = compiler.compileClassImpl(null, [], []);
        assertEqual(nullClassResult, null, "Should return null for null class");
        
        var nullEnumResult = compiler.compileEnumImpl(null, []);
        assertEqual(nullEnumResult, null, "Should return null for null enum");
        
        var nullExprResult = compiler.compileExpressionImpl(null, false);
        assertEqual(nullExprResult, null, "Should return null for null expression");
        
        // Test constant compilation
        // Note: We'll need to create mock constants since we can't easily create TConstant instances
        
        trace("✅ Elixir code generation test passed");
    }
    
    /**
     * Helper: Assert equality with descriptive messages
     */
    static function assertEqual<T>(actual: T, expected: T, message: String) {
        if (actual != expected) {
            var error = '❌ ASSERTION FAILED: ${message}\n  Expected: ${expected}\n  Actual: ${actual}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}: ${actual}');
        }
    }
}