package test;

// Integration test for ElixirCompiler - Testing Trophy focused

import utest.Test;
import utest.Assert;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.NamingHelper;

class IntegrationTest extends Test {
    
    /**
     * Test naming convention utilities work as expected
     */
    public function testNamingConventions() {
        // Test snake_case conversion
        Assert.equals("my_class", NamingHelper.toSnakeCase("MyClass"), "MyClass -> my_class");
        Assert.equals("some_method", NamingHelper.toSnakeCase("someMethod"), "someMethod -> some_method");
        Assert.equals("h_t_t_p_client", NamingHelper.toSnakeCase("HTTPClient"), "HTTPClient -> h_t_t_p_client");
        
        // Test CamelCase conversion
        Assert.equals("MyClass", NamingHelper.toCamelCase("my_class"), "my_class -> MyClass");
        Assert.equals("SomeMethod", NamingHelper.toCamelCase("some_method"), "some_method -> SomeMethod");
        
        // Test Elixir module names
        Assert.equals("MyClass", NamingHelper.getElixirModuleName("MyClass"), "Simple module name");
        Assert.equals("Com.Example.MyClass", NamingHelper.getElixirModuleName("com.example.MyClass"), "Nested module name");
        
        // Test Elixir function names
        Assert.equals("some_method", NamingHelper.getElixirFunctionName("someMethod"), "Function name conversion");
        Assert.equals("__struct__", NamingHelper.getElixirFunctionName("new"), "Constructor mapping");
    }
    
    /**
     * Test basic compiler instantiation and configuration
     */
    public function testBasicCompilerSetup() {
        var compiler = new ElixirCompiler();
        
        // Test configuration
        Assert.equals(".ex", compiler.fileExtension, "File extension should be .ex");
        Assert.equals("lib/", compiler.outputDirectory, "Output directory should be lib/");
        
        // Test naming utility integration
        Assert.equals("my_class", compiler.toElixirName("MyClass"), "Compiler naming utility works");
    }
    
    /**
     * Test file extension and output directory configuration
     */
    public function testFileExtensionAndDirectory() {
        var compiler = new ElixirCompiler();
        
        // These should be properly configured for Elixir
        Assert.equals(".ex", compiler.fileExtension, "Should use .ex extension");
        Assert.equals("lib/", compiler.outputDirectory, "Should output to lib/ directory");
    }
    
    /**
     * Test actual Elixir code generation from method calls
     */
    public function testElixirCodeGeneration() {
        var compiler = new ElixirCompiler();
        
        // Test null handling - these methods should gracefully handle null inputs
        var nullClassResult = compiler.compileClassImpl(null, [], []);
        Assert.equals(null, nullClassResult, "Should return null for null class");
        
        var nullEnumResult = compiler.compileEnumImpl(null, []);
        Assert.equals(null, nullEnumResult, "Should return null for null enum");
        
        var nullExprResult = compiler.compileExpressionImpl(null, false);
        Assert.equals(null, nullExprResult, "Should return null for null expression");
        
        // Test that compiler instance is properly initialized
        Assert.notNull(compiler, "Compiler should be instantiated");
        
        // Note: More detailed code generation tests would require creating TypedExpr instances
        // which are complex and are better tested through integration with the full compilation pipeline
    }
    
    static function main() {
        var runner = new utest.Runner();
        runner.addCase(new IntegrationTest());
        var report = utest.ui.Report.create(runner);
        runner.run();
    }
}