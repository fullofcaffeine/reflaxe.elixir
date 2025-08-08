package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;

/**
 * Unit tests for enum compilation - Testing Trophy focused
 * Tests enum→tagged tuple compilation with proper type safety
 */
class EnumCompilationTest {
    public static function main() {
        trace("Running Enum Compilation Tests...");
        
        testSimpleEnumCompilation();
        testParameterizedEnumCompilation();
        testEnumTypeGeneration();
        testEnumConstructorGeneration();
        testNoAnyTypesInEnums();
        
        trace("✅ All Enum Compilation tests passed!");
    }
    
    /**
     * Test compilation of simple enums to atoms
     */
    static function testSimpleEnumCompilation() {
        trace("TEST: Simple enum compilation to atoms");
        
        // This test will initially fail - RED phase
        var compiler = new ElixirCompiler();
        
        // Mock simple enum data: Status { None; Ready; Error; }
        var enumType = createMockEnumType("Status", "Test status enum");
        var options = [
            createMockEnumOption("None", []),
            createMockEnumOption("Ready", []),
            createMockEnumOption("Error", [])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Check basic structure
        assertTrue(result != null, "Enum compilation should not return null");
        assertTrue(result.indexOf("defmodule Status") >= 0, "Should create Status module");
        
        // Check atom generation for simple enums
        assertTrue(result.indexOf(":none") >= 0, "Should generate :none atom");
        assertTrue(result.indexOf(":ready") >= 0, "Should generate :ready atom");
        assertTrue(result.indexOf(":error") >= 0, "Should generate :error atom");
        
        // Check constructor functions
        assertTrue(result.indexOf("def none(), do: :none") >= 0, "Should have simple atom constructor");
        assertTrue(result.indexOf("def ready(), do: :ready") >= 0, "Should have ready constructor");
        
        trace("✅ Simple enum compilation test passed");
    }
    
    /**
     * Test compilation of parameterized enums to tagged tuples
     */
    static function testParameterizedEnumCompilation() {
        trace("TEST: Parameterized enum compilation to tagged tuples");
        
        var compiler = new ElixirCompiler();
        
        // Mock parameterized enum: Result<T> { Success(value: T); Failure(error: String); }
        var enumType = createMockEnumType("Result", "Result type for operations");
        var options = [
            createMockEnumOption("Success", [createMockArg("value", "T")]),
            createMockEnumOption("Failure", [createMockArg("error", "String")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Check tagged tuple generation
        assertTrue(result.indexOf("{:success, ") >= 0, "Should generate tagged tuple for Success");
        assertTrue(result.indexOf("{:failure, ") >= 0, "Should generate tagged tuple for Failure");
        
        // Check constructor functions with parameters
        assertTrue(result.indexOf("def success(arg0)") >= 0, "Should have parameterized constructor");
        assertTrue(result.indexOf("{:success, arg0}") >= 0, "Should return tagged tuple");
        
        trace("✅ Parameterized enum compilation test passed");
    }
    
    /**
     * Test @type generation for enums
     */
    static function testEnumTypeGeneration() {
        trace("TEST: Enum @type generation");
        
        var compiler = new ElixirCompiler();
        var enumType = createMockEnumType("Option", "Optional value type");
        var options = [
            createMockEnumOption("None", []),
            createMockEnumOption("Some", [createMockArg("value", "String")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Check @type definition exists
        assertTrue(result.indexOf("@type t() ::") >= 0, "Should have @type definition");
        assertTrue(result.indexOf(":none") >= 0, "Should have none type option");
        assertTrue(result.indexOf("{:some,") >= 0, "Should have tagged tuple type option");
        
        trace("✅ Enum @type generation test passed");
    }
    
    /**
     * Test constructor function generation
     */
    static function testEnumConstructorGeneration() {
        trace("TEST: Enum constructor function generation");
        
        var compiler = new ElixirCompiler();
        var enumType = createMockEnumType("Message", "Message types");
        var options = [
            createMockEnumOption("Info", [createMockArg("text", "String")]),
            createMockEnumOption("Warning", [createMockArg("text", "String"), createMockArg("level", "Int")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Check single parameter constructor
        assertTrue(result.indexOf("def info(arg0)") >= 0, "Should have single param constructor");
        assertTrue(result.indexOf("{:info, arg0}") >= 0, "Should return single param tuple");
        
        // Check multi-parameter constructor  
        assertTrue(result.indexOf("def warning(arg0, arg1)") >= 0, "Should have multi-param constructor");
        assertTrue(result.indexOf("{:warning, arg0, arg1}") >= 0, "Should return multi-param tuple");
        
        trace("✅ Enum constructor generation test passed");
    }
    
    /**
     * Test that no any() types are generated per PRD requirements
     */
    static function testNoAnyTypesInEnums() {
        trace("TEST: No any() types in enum compilation per PRD");
        
        var compiler = new ElixirCompiler();
        var enumType = createMockEnumType("Data", "Data container");
        var options = [
            createMockEnumOption("Value", [createMockArg("data", "String")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Should not contain any() - this will initially fail
        assertFalse(result.indexOf("any()") >= 0, "Enum compilation should not use any() types per PRD");
        
        trace("✅ No any() types test passed");
    }
    
    // Mock helper functions for testing
    static function createMockEnumType(name: String, doc: String) {
        return {
            getNameOrNative: function() return name,
            doc: doc
        };
    }
    
    static function createMockEnumOption(name: String, args: Array<Dynamic>) {
        return {
            field: { name: name },
            args: args
        };
    }
    
    static function createMockArg(name: String, type: String) {
        return {
            name: name,
            t: type
        };
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
        if (condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
    }
}

#end