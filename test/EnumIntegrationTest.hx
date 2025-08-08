package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.ElixirTyper;

/**
 * Integration tests for enum compilation - Testing Trophy focused
 * Verifies complete enum→tagged tuple system integration
 */
class EnumIntegrationTest {
    public static function main() {
        trace("Running Enum Integration Tests...");
        
        testCompleteEnumSystemIntegration();
        testEnumWithTypeIntegration();
        testPatternMatchingGeneration();
        testRealWorldEnumScenarios();
        testPhoenixCompatibleEnums();
        
        trace("✅ All Enum Integration tests passed!");
    }
    
    /**
     * Test complete enum system with real-world Result type
     */
    static function testCompleteEnumSystemIntegration() {
        trace("TEST: Complete enum system integration");
        
        var compiler = new ElixirCompiler();
        var typer = new ElixirTyper();
        
        // Test Result<String> enum compilation
        var enumType = createMockEnumType("Result", "Result type for string operations");
        var options = [
            createMockEnumOption("Ok", [createMockArg("value", "String")]),
            createMockEnumOption("Error", [createMockArg("message", "String")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Verify complete module structure
        assertTrue(result.indexOf("defmodule Result do") >= 0, "Should create Result module");
        assertTrue(result.indexOf("@moduledoc") >= 0, "Should have module documentation");
        assertTrue(result.indexOf("@type t() ::") >= 0, "Should have type definition");
        
        // Verify tagged tuple generation
        assertTrue(result.indexOf("{:ok,") >= 0, "Should generate {:ok, value} tuple type");
        assertTrue(result.indexOf("{:error,") >= 0, "Should generate {:error, message} tuple type");
        
        // Verify constructor functions
        assertTrue(result.indexOf("def ok(arg0)") >= 0, "Should have ok constructor");
        assertTrue(result.indexOf("def error(arg0)") >= 0, "Should have error constructor");
        assertTrue(result.indexOf("{:ok, arg0}") >= 0, "Should return proper tagged tuple");
        
        // Verify type integration with ElixirTyper
        var resultType = typer.compileType("Result");
        assertEqual(resultType, "Result.t()", "Should generate proper Result type reference");
        
        trace("✅ Complete enum system integration test passed");
    }
    
    /**
     * Test enum integration with ElixirTyper for proper type generation
     */
    static function testEnumWithTypeIntegration() {
        trace("TEST: Enum with ElixirTyper integration");
        
        var compiler = new ElixirCompiler();
        var typer = new ElixirTyper();
        
        // Test Option<T> enum with generic parameter
        var enumType = createMockEnumType("Option", "Optional value container");
        var options = [
            createMockEnumOption("None", []),
            createMockEnumOption("Some", [createMockArg("value", "Dynamic")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Should integrate with type system properly
        assertTrue(result.indexOf("@type t()") >= 0, "Should have type definition");
        assertTrue(result.indexOf(":none") >= 0, "Should include None option");
        assertTrue(result.indexOf("{:some,") >= 0, "Should include Some tagged tuple");
        
        // Should NOT use any() - must use proper types from typer
        assertFalse(result.indexOf("any()") >= 0, "Should not use any() types per PRD");
        
        trace("✅ Enum with ElixirTyper integration test passed");
    }
    
    /**
     * Test pattern matching code generation for switch expressions
     */
    static function testPatternMatchingGeneration() {
        trace("TEST: Pattern matching generation for enums");
        
        var compiler = new ElixirCompiler();
        
        // Test enum with mixed simple and parameterized options
        var enumType = createMockEnumType("Status", "Status enumeration");
        var options = [
            createMockEnumOption("Idle", []),
            createMockEnumOption("Loading", [createMockArg("progress", "Int")]),
            createMockEnumOption("Complete", [createMockArg("result", "String")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Should generate pattern matching helper
        assertTrue(result.indexOf("def match(value, patterns)") >= 0, "Should have match helper function");
        assertTrue(result.indexOf("case value do") >= 0, "Should use case expression");
        
        // Should handle both atom and tagged tuple patterns
        assertTrue(result.indexOf(":idle ->") >= 0, "Should pattern match atoms");
        assertTrue(result.indexOf("{:loading, arg0} ->") >= 0, "Should pattern match tagged tuples");
        
        trace("✅ Pattern matching generation test passed");
    }
    
    /**
     * Test real-world enum scenarios that Phoenix applications use
     */
    static function testRealWorldEnumScenarios() {
        trace("TEST: Real-world enum scenarios");
        
        var compiler = new ElixirCompiler();
        
        // HTTP Response enum - common Phoenix pattern
        var enumType = createMockEnumType("HttpResponse", "HTTP response types");
        var options = [
            createMockEnumOption("Ok", [createMockArg("body", "String")]),
            createMockEnumOption("NotFound", []),
            createMockEnumOption("ServerError", [createMockArg("message", "String"), createMockArg("code", "Int")])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Should generate Phoenix-compatible patterns
        assertTrue(result.indexOf("{:ok, arg0}") >= 0, "Should match Phoenix {:ok, _} pattern");
        assertTrue(result.indexOf(":not_found") >= 0, "Should use proper snake_case atoms");
        assertTrue(result.indexOf("{:server_error, arg0, arg1}") >= 0, "Should handle multi-arg tuples");
        
        // Should have proper constructor functions
        assertTrue(result.indexOf("def ok(arg0)") >= 0, "Should have ok constructor");
        assertTrue(result.indexOf("def not_found(), do: :not_found") >= 0, "Should have atom constructor");
        assertTrue(result.indexOf("def server_error(arg0, arg1)") >= 0, "Should have multi-arg constructor");
        
        trace("✅ Real-world enum scenarios test passed");
    }
    
    /**
     * Test Phoenix-compatible enum generation patterns
     */
    static function testPhoenixCompatibleEnums() {
        trace("TEST: Phoenix-compatible enum patterns");
        
        var compiler = new ElixirCompiler();
        
        // LiveView event enum
        var enumType = createMockEnumType("LiveViewEvent", "LiveView event types");
        var options = [
            createMockEnumOption("Click", [createMockArg("element", "String")]),
            createMockEnumOption("Submit", [createMockArg("form", "Map<String, String>")]),
            createMockEnumOption("Mount", [])
        ];
        
        var result = compiler.compileEnumImpl(enumType, options);
        
        // Should generate @type definition compatible with Phoenix typespecs
        assertTrue(result.indexOf("@type t() ::") >= 0, "Should have typespec definition");
        
        // Should use proper Elixir naming conventions
        assertTrue(result.indexOf("{:click,") >= 0, "Should use snake_case in types");
        assertTrue(result.indexOf("{:submit,") >= 0, "Should convert camelCase to snake_case");
        assertTrue(result.indexOf(":mount") >= 0, "Should handle simple atoms correctly");
        
        // Should generate documentation  
        assertTrue(result.indexOf("@doc") >= 0, "Should generate function documentation");
        assertTrue(result.indexOf("@moduledoc") >= 0, "Should generate module documentation");
        
        trace("✅ Phoenix-compatible enum patterns test passed");
    }
    
    // Mock helper functions
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
    
    static function assertEqual<T>(actual: T, expected: T, message: String) {
        if (actual != expected) {
            var error = '❌ ASSERTION FAILED: ${message}\\n  Expected: ${expected}\\n  Actual: ${actual}';
            trace(error);
            throw error;
        } else {
            trace('  ✓ ${message}: ${actual}');
        }
    }
}

#end