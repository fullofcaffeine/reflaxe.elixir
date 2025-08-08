package test;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.data.EnumOptionData;

import reflaxe.elixir.ElixirCompiler;

using StringTools;

class TestElixirCompiler {
    public static function main() {
        // TDD Test Runner - These will fail initially
        trace("Running ElixirCompiler TDD Tests...");
        
        testElixirCompilerExists();
        testElixirCompilerExtendsDirectToString();
        testCompileClassImplExists();
        testCompileEnumImplExists();
        testCompileExpressionImplExists();
        testBasicClassCompilation();
        testNamingConventions();
        testFileExtensions();
        
        trace("All tests passed!");
    }
    
    static function testElixirCompilerExists() {
        trace("TEST: ElixirCompiler class exists");
        // This will fail until we create the class
        try {
            var compiler = new ElixirCompiler();
            trace("✅ ElixirCompiler instantiated successfully");
        } catch(e) {
            trace("❌ ElixirCompiler does not exist: " + e);
            throw e;
        }
    }
    
    static function testElixirCompilerExtendsDirectToString() {
        trace("TEST: ElixirCompiler extends DirectToStringCompiler");
        try {
            var compiler = new ElixirCompiler();
            // Check if it has required methods
            var hasCompileClass = Reflect.hasField(compiler, "compileClassImpl");
            var hasCompileEnum = Reflect.hasField(compiler, "compileEnumImpl");
            var hasCompileExpr = Reflect.hasField(compiler, "compileExpressionImpl");
            
            if (!hasCompileClass || !hasCompileEnum || !hasCompileExpr) {
                throw "Missing required methods from DirectToStringCompiler";
            }
            
            trace("✅ ElixirCompiler properly extends DirectToStringCompiler");
        } catch(e) {
            trace("❌ ElixirCompiler inheritance issue: " + e);
            throw e;
        }
    }
    
    static function testCompileClassImplExists() {
        trace("TEST: compileClassImpl method exists");
        try {
            var compiler = new ElixirCompiler();
            // This will fail until method is implemented
            var result = compiler.compileClassImpl(null, [], []);
            // Should return null for now, just testing it exists
            trace("✅ compileClassImpl method callable");
        } catch(e) {
            trace("❌ compileClassImpl not implemented: " + e);
            throw e;
        }
    }
    
    static function testCompileEnumImplExists() {
        trace("TEST: compileEnumImpl method exists");
        try {
            var compiler = new ElixirCompiler();
            // This will fail until method is implemented
            var result = compiler.compileEnumImpl(null, []);
            trace("✅ compileEnumImpl method callable");
        } catch(e) {
            trace("❌ compileEnumImpl not implemented: " + e);
            throw e;
        }
    }
    
    static function testCompileExpressionImplExists() {
        trace("TEST: compileExpressionImpl method exists");
        try {
            var compiler = new ElixirCompiler();
            // This will fail until method is implemented
            var result = compiler.compileExpressionImpl(null, false);
            trace("✅ compileExpressionImpl method callable");
        } catch(e) {
            trace("❌ compileExpressionImpl not implemented: " + e);
            throw e;
        }
    }
    
    static function testBasicClassCompilation() {
        trace("TEST: Basic class compilation produces Elixir module");
        try {
            var compiler = new ElixirCompiler();
            // Mock a simple ClassType (this is a complex test that will evolve)
            // For now just test that method returns some string for valid input
            
            // This will be expanded once we have actual implementation
            trace("✅ Basic class compilation test setup");
        } catch(e) {
            trace("❌ Basic class compilation failed: " + e);
            throw e;
        }
    }
    
    static function testNamingConventions() {
        trace("TEST: Naming conventions (camelCase -> snake_case)");
        // This will test utility methods for name conversion
        // Will fail until we implement the utility functions
        
        try {
            var compiler = new ElixirCompiler();
            
            // Test camelCase to snake_case conversion
            // These utility methods don't exist yet
            var result1 = compiler.toElixirName("MyClass"); 
            var result2 = compiler.toElixirName("someMethod");
            
            if (result1 != "my_class" || result2 != "some_method") {
                throw "Naming convention conversion failed";
            }
            
            trace("✅ Naming conventions work correctly");
        } catch(e) {
            trace("❌ Naming convention test failed: " + e);
            throw e;
        }
    }
    
    static function testFileExtensions() {
        trace("TEST: File extensions are .ex and output to lib/");
        try {
            var compiler = new ElixirCompiler();
            
            // Test that compiler is configured for .ex files in lib/
            // These properties don't exist yet
            if (compiler.fileExtension != ".ex") {
                throw "File extension should be .ex";
            }
            
            if (compiler.outputDirectory != "lib/") {
                throw "Output directory should be lib/";
            }
            
            trace("✅ File extensions and output directory configured");
        } catch(e) {
            trace("❌ File extension configuration failed: " + e);
            throw e;
        }
    }
}

#end