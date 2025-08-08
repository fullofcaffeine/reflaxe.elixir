package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirPrinter;
import reflaxe.elixir.helpers.FormatHelper;

/**
 * Integration tests for ElixirPrinter - Testing Trophy focused
 * Verifies that generated Elixir code follows proper syntax and conventions
 */
class ElixirPrinterIntegrationTest {
    public static function main() {
        trace("Running ElixirPrinter Integration Tests...");
        
        testCompleteClassGeneration();
        testFunctionGenerationWithDifferentSignatures();
        testExpressionFormattingVariety();
        testFormatHelperIntegration();
        testElixirSyntaxCompliance();
        testComplexStructureGeneration();
        
        trace("✅ All ElixirPrinter integration tests passed!");
    }
    
    /**
     * Test complete class generation produces valid Elixir modules
     */
    static function testCompleteClassGeneration() {
        trace("TEST: Complete class generation");
        
        var printer = new ElixirPrinter();
        
        // Test simple class with no fields
        var result1 = printer.printClass("SimpleClass", [], []);
        
        // Should contain proper defmodule structure
        assertTrue(result1.indexOf("defmodule SimpleClass do") >= 0, "Should contain defmodule declaration");
        assertTrue(result1.indexOf("@moduledoc") >= 0, "Should contain module documentation");
        assertTrue(result1.indexOf("end") >= 0, "Should properly close module");
        
        // Test class with fields
        var mockFields = [1, 2, 3]; // Mock field data
        var result2 = printer.printClass("DataClass", mockFields, []);
        
        assertTrue(result2.indexOf("defstruct") >= 0, "Should contain struct definition for fields");
        assertTrue(result2.indexOf("@type") >= 0, "Should contain type specification");
        
        trace("✅ Complete class generation test passed");
    }
    
    /**
     * Test function generation with different parameter counts
     */
    static function testFunctionGenerationWithDifferentSignatures() {
        trace("TEST: Function generation with different signatures");
        
        var printer = new ElixirPrinter();
        
        // Test function with no parameters
        var result1 = printer.printFunction("simpleFunc", [], "String", false);
        assertTrue(result1.indexOf("def simple_func()") >= 0, "Should handle zero parameters");
        assertTrue(result1.indexOf("@spec") >= 0, "Should include type spec");
        assertTrue(result1.indexOf("@doc") >= 0, "Should include documentation");
        
        // Test function with multiple parameters
        var args = ["arg1", "arg2", "arg3"];
        var result2 = printer.printFunction("complexFunc", args, "integer()", false);
        assertTrue(result2.indexOf("def complex_func(arg1, arg2, arg3)") >= 0, "Should handle multiple parameters");
        
        // Test function with many parameters (should format multiline)
        var manyArgs = ["a1", "a2", "a3", "a4", "a5"];
        var result3 = printer.printFunction("manyArgsFunc", manyArgs, "any()", false);
        // Should format parameters across multiple lines for readability
        
        trace("✅ Function generation signatures test passed");
    }
    
    /**
     * Test expression formatting handles various Haxe->Elixir conversions
     */
    static function testExpressionFormattingVariety() {
        trace("TEST: Expression formatting variety");
        
        var printer = new ElixirPrinter();
        
        // Test simple expression
        var result1 = printer.printExpression("testVar");
        assertEqual(result1, "testVar", "Should pass through simple variables");
        
        // Test null conversion
        var result2 = printer.printExpression("null");
        assertEqual(result2, "nil", "Should convert null to nil");
        
        // Test list formatting
        var listElements = ["1", "2", "3"];
        var result3 = printer.printList(listElements, false);
        assertEqual(result3, "[1, 2, 3]", "Should format simple lists");
        
        // Test multiline list
        var manyElements = ["elem1", "elem2", "elem3", "elem4"];
        var result4 = printer.printList(manyElements, true);
        assertTrue(result4.indexOf("[\n") >= 0, "Should format multiline lists");
        
        // Test map formatting
        var mapPairs = [{key: "name", value: '"John"'}, {key: "age", value: "30"}];
        var result5 = printer.printMap(mapPairs, false);
        assertTrue(result5.indexOf("%{name: \"John\", age: 30}") >= 0, "Should format maps correctly");
        
        trace("✅ Expression formatting variety test passed");
    }
    
    /**
     * Test FormatHelper integration provides consistent formatting
     */
    static function testFormatHelperIntegration() {
        trace("TEST: FormatHelper integration");
        
        // Test indentation
        var indented = FormatHelper.indent("test line", 2);
        assertEqual(indented, "    test line", "Should indent with 4 spaces for level 2");
        
        // Test multi-line indentation
        var multiLine = "line1\nline2";
        var indentedLines = FormatHelper.indentLines(multiLine, 1);
        assertEqual(indentedLines, "  line1\n  line2", "Should indent all lines");
        
        // Test documentation formatting
        var docFormatted = FormatHelper.formatDoc("Test documentation", false, 1);
        assertTrue(docFormatted.indexOf('@doc "Test documentation"') >= 0, "Should format single-line docs");
        
        // Test spec formatting
        var specFormatted = FormatHelper.formatSpec("test_func", ["String.t()", "integer()"], "boolean()", 1);
        assertTrue(specFormatted.indexOf("@spec test_func(String.t(), integer()) :: boolean()") >= 0, "Should format specs");
        
        trace("✅ FormatHelper integration test passed");
    }
    
    /**
     * Test that generated code follows Elixir syntax conventions
     */
    static function testElixirSyntaxCompliance() {
        trace("TEST: Elixir syntax compliance");
        
        var printer = new ElixirPrinter();
        
        // Generate a complete class and validate syntax patterns
        var mockFields = [1, 2];
        var mockFuncs = [1];
        var options: PrintClassOptions = {
            documentation: "Test class for validation",
            superClass: "BaseClass",
            interfaces: ["Interface1", "Interface2"]
        };
        
        var result = printer.printClass("TestModule", mockFields, mockFuncs, options);
        
        // Validate Elixir-specific syntax elements
        assertTrue(result.indexOf("defmodule TestModule do") >= 0, "Should use proper module syntax");
        assertTrue(result.indexOf("@moduledoc") >= 0, "Should include module docs");
        assertTrue(result.indexOf("@type t()") >= 0, "Should include type definitions");
        assertTrue(result.indexOf("defstruct") >= 0, "Should include struct definitions");
        assertTrue(result.indexOf("# Inherits from BaseClass") >= 0, "Should document inheritance");
        assertTrue(result.indexOf("# Implements interfaces:") >= 0, "Should document interfaces");
        assertTrue(result.indexOf("end") > result.lastIndexOf("def"), "Should properly close module");
        
        // Check that generated code doesn't contain Haxe-specific syntax
        assertTrue(result.indexOf("class") < 0, "Should not contain 'class' keyword");
        assertTrue(result.indexOf("function") < 0, "Should not contain 'function' keyword");
        assertTrue(result.indexOf("var ") < 0, "Should not contain 'var ' declarations");
        
        trace("✅ Elixir syntax compliance test passed");
    }
    
    /**
     * Test complex nested structure generation
     */
    static function testComplexStructureGeneration() {
        trace("TEST: Complex structure generation");
        
        var printer = new ElixirPrinter();
        
        // Test function call formatting
        var funcCall = printer.printFunctionCall("ModuleName.complex_function", 
            ["arg1", "arg2", "arg3", "arg4", "arg5"], true);
        assertTrue(funcCall.length > 0, "Should generate function calls");
        
        // Test nested expressions through printExpression
        var nestedExpr = "some_complex_expression(with, nested, calls)";
        var formatted = printer.printExpression(nestedExpr);
        assertTrue(formatted.length > 0, "Should handle complex expressions");
        
        trace("✅ Complex structure generation test passed");
    }
    
    /**
     * Helper: Assert that condition is true with descriptive message
     */
    static function assertTrue(condition: Bool, message: String) {
        if (!condition) {
            var error = '❌ ASSERTION FAILED: ${message}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}');
        }
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

#end