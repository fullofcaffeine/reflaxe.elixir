package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ExternGenerator;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Test suite for extern generation from Elixir modules
 */
class ExternGenerationTest {
    public static function main() {
        trace("Running Extern Generation Tests...");
        
        testBasicExternGeneration();
        testComplexModuleGeneration();
        testStructGeneration();
        testTypeConversions();
        testDirectoryProcessing();
        testErrorHandling();
        
        trace("✅ All extern generation tests passed!");
    }
    
    /**
     * Test basic extern generation from simple module
     */
    static function testBasicExternGeneration() {
        trace("TEST: Basic extern generation");
        
        var simpleModule = "test/fixtures/sample_elixir/simple_module.ex";
        var result = ExternGenerator.generateFromFile(simpleModule);
        
        
        assertTrue(result.contains("extern class Simple"), "Should generate extern class");
        assertTrue(result.contains('@:native("Simple")'), "Should add native annotation");
        assertTrue(result.contains("static function hello()"), "Should generate hello function");
        assertTrue(result.contains("static function echo(arg0: Dynamic)"), "Should generate echo function");
        assertTrue(result.contains("String"), "Should convert atom() to String");
        
        trace("✅ Basic extern generation test passed");
    }
    
    /**
     * Test complex module with specs and types
     */
    static function testComplexModuleGeneration() {
        trace("TEST: Complex module generation");
        
        var mathModule = "test/fixtures/sample_elixir/math_helper.ex";
        var result = ExternGenerator.generateFromFile(mathModule);
        
        
        assertTrue(result.contains("extern class MathHelper"), "Should generate MathHelper class");
        assertTrue(result.contains("static function add(arg0: Int, arg1: Int): Int"), "Should handle integer specs");
        assertTrue(result.contains("static function multiply("), "Should generate multiply function");
        assertTrue(result.contains("static function isPositive("), "Should handle predicate functions");
        assertTrue(result.contains("static function squareUnsafe("), "Should handle bang functions");
        assertTrue(result.contains("Array<Float>"), "Should convert list(number()) to Array<Float>");
        
        trace("✅ Complex module generation test passed");
    }
    
    /**
     * Test struct generation
     */
    static function testStructGeneration() {
        trace("TEST: Struct generation");
        
        var userModule = "test/fixtures/sample_elixir/user.ex";
        var result = ExternGenerator.generateFromFile(userModule);
        
        assertTrue(result.contains("package myapp;"), "Should generate correct package");
        assertTrue(result.contains("extern class User"), "Should generate User class");
        assertTrue(result.contains("UserStruct"), "Should generate struct typedef");
        assertTrue(result.contains("?id: Dynamic"), "Should include struct fields");
        assertTrue(result.contains("?name: Dynamic"), "Should include name field");
        assertTrue(result.contains("?active: Dynamic"), "Should include active field");
        
        trace("✅ Struct generation test passed");
    }
    
    /**
     * Test type conversion accuracy
     */
    static function testTypeConversions() {
        trace("TEST: Type conversion accuracy");
        
        var mathModule = "test/fixtures/sample_elixir/math_helper.ex";
        var result = ExternGenerator.generateFromFile(mathModule);
        
        // Test basic type conversions
        assertTrue(result.contains("Int"), "Should convert integer() to Int");
        assertTrue(result.contains("Float"), "Should convert number() to Float");
        assertTrue(result.contains("String"), "Should convert String.t() to String");
        assertTrue(result.contains("Bool"), "Should convert boolean() to Bool");
        
        // Test complex type conversions
        assertTrue(result.contains("Array<"), "Should convert list() to Array<>");
        assertTrue(result.contains("Dynamic"), "Should use Dynamic for complex types");
        
        trace("✅ Type conversion test passed");
    }
    
    /**
     * Test directory processing
     */
    static function testDirectoryProcessing() {
        trace("TEST: Directory processing");
        
        var inputDir = "test/fixtures/sample_elixir";
        var outputDir = "test/output/externs";
        
        // Ensure output directory exists
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }
        
        var generated = ExternGenerator.generateFromDirectory(inputDir, outputDir);
        
        assertTrue(generated.length > 0, "Should generate files from directory");
        assertTrue(generated.length >= 3, "Should process all test files");
        
        // Verify generated files exist
        for (file in generated) {
            assertTrue(FileSystem.exists(file), 'Generated file should exist: ${file}');
        }
        
        trace("✅ Directory processing test passed");
    }
    
    /**
     * Test error handling for malformed/missing files
     */
    static function testErrorHandling() {
        trace("TEST: Error handling");
        
        // Test missing file
        try {
            ExternGenerator.generateFromFile("nonexistent.ex");
            assertTrue(false, "Should throw error for missing file");
        } catch (e: Dynamic) {
            assertTrue(Std.string(e).contains("not found"), "Should throw appropriate error");
        }
        
        // Test file without module definition
        var invalidFile = "test/fixtures/sample_elixir/invalid.ex";
        File.saveContent(invalidFile, "def some_function, do: :ok");
        
        try {
            ExternGenerator.generateFromFile(invalidFile);
            assertTrue(false, "Should throw error for file without module");
        } catch (e: Dynamic) {
            assertTrue(Std.string(e).contains("No module definition"), "Should detect missing module");
        }
        
        // Clean up
        if (FileSystem.exists(invalidFile)) {
            FileSystem.deleteFile(invalidFile);
        }
        
        trace("✅ Error handling test passed");
    }
    
    // Test helper functions
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
    
    static function assertFalse(condition: Bool, message: String) {
        assertTrue(!condition, message);
    }
}

#end