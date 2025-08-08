package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirPrinter;
import reflaxe.elixir.helpers.FormatHelper;

/**
 * TDD Tests for ElixirPrinter - Testing Trophy focused
 * These tests will initially fail until we implement the ElixirPrinter
 */
class ElixirPrinterTest {
    public static function main() {
        trace("Running ElixirPrinter TDD Tests...");
        
        testElixirPrinterExists();
        testPrintClassMethod();
        testPrintFunctionMethod();
        testPrintExpressionMethod();
        testPrintTypeMethod();
        testFormatHelperExists();
        testIndentationUtilities();
        testElixirSyntaxFormatting();
        
        trace("✅ All ElixirPrinter tests passed!");
    }
    
    static function testElixirPrinterExists() {
        trace("TEST: ElixirPrinter class exists and can be instantiated");
        try {
            var printer = new ElixirPrinter();
            trace("✅ ElixirPrinter instantiated successfully");
        } catch(e) {
            trace("❌ ElixirPrinter does not exist: " + e);
            throw e;
        }
    }
    
    static function testPrintClassMethod() {
        trace("TEST: printClass method exists");
        try {
            var printer = new ElixirPrinter();
            
            // Test method existence - will fail until implemented
            var result = printer.printClass("TestClass", [], []);
            
            // Should return some string output for valid input
            if (result == null || result.length == 0) {
                throw "printClass should return non-empty string for valid input";
            }
            
            // Should contain basic defmodule structure
            if (!result.contains("defmodule")) {
                throw "printClass should generate defmodule structure";
            }
            
            trace("✅ printClass method works correctly");
        } catch(e) {
            trace("❌ printClass method failed: " + e);
            throw e;
        }
    }
    
    static function testPrintFunctionMethod() {
        trace("TEST: printFunction method exists");
        try {
            var printer = new ElixirPrinter();
            
            // Test method existence - will fail until implemented
            var result = printer.printFunction("test_function", [], "String", false);
            
            // Should return valid function definition
            if (result == null || result.length == 0) {
                throw "printFunction should return non-empty string";
            }
            
            // Should contain def keyword
            if (!result.contains("def")) {
                throw "printFunction should generate def structure";
            }
            
            trace("✅ printFunction method works correctly");
        } catch(e) {
            trace("❌ printFunction method failed: " + e);
            throw e;
        }
    }
    
    static function testPrintExpressionMethod() {
        trace("TEST: printExpression method exists");
        try {
            var printer = new ElixirPrinter();
            
            // Test method existence - will fail until implemented
            var result = printer.printExpression("test_var");
            
            // Should return the expression as-is for simple cases
            if (result != "test_var") {
                throw "printExpression should handle simple variables correctly";
            }
            
            trace("✅ printExpression method works correctly");
        } catch(e) {
            trace("❌ printExpression method failed: " + e);
            throw e;
        }
    }
    
    static function testPrintTypeMethod() {
        trace("TEST: printType method exists");
        try {
            var printer = new ElixirPrinter();
            
            // Test method existence - will fail until implemented
            var result = printer.printType("String");
            
            // Should return Elixir type equivalent
            if (result != "String.t()") {
                throw "printType should convert Haxe types to Elixir types";
            }
            
            trace("✅ printType method works correctly");
        } catch(e) {
            trace("❌ printType method failed: " + e);
            throw e;
        }
    }
    
    static function testFormatHelperExists() {
        trace("TEST: FormatHelper utility class exists");
        try {
            // Test static method access - will fail until implemented
            var indented = FormatHelper.indent("test", 2);
            
            if (indented != "  test") {
                throw "FormatHelper.indent should add proper indentation";
            }
            
            trace("✅ FormatHelper utility works correctly");
        } catch(e) {
            trace("❌ FormatHelper utility failed: " + e);
            throw e;
        }
    }
    
    static function testIndentationUtilities() {
        trace("TEST: Indentation utilities work correctly");
        try {
            // Test multi-line indentation
            var multiLine = "line1\nline2\nline3";
            var indented = FormatHelper.indentLines(multiLine, 1);
            
            var expected = "  line1\n  line2\n  line3";
            if (indented != expected) {
                throw "FormatHelper.indentLines should indent all lines correctly";
            }
            
            trace("✅ Indentation utilities work correctly");
        } catch(e) {
            trace("❌ Indentation utilities failed: " + e);
            throw e;
        }
    }
    
    static function testElixirSyntaxFormatting() {
        trace("TEST: Elixir syntax formatting utilities");
        try {
            var printer = new ElixirPrinter();
            
            // Test module documentation formatting
            var docString = printer.formatModuleDoc("Test module");
            if (!docString.contains('@moduledoc')) {
                throw "formatModuleDoc should generate @moduledoc structure";
            }
            
            // Test function documentation formatting
            var funcDoc = printer.formatFunctionDoc("Test function");
            if (!funcDoc.contains('@doc')) {
                throw "formatFunctionDoc should generate @doc structure";
            }
            
            trace("✅ Elixir syntax formatting works correctly");
        } catch(e) {
            trace("❌ Elixir syntax formatting failed: " + e);
            throw e;
        }
    }
}

#end