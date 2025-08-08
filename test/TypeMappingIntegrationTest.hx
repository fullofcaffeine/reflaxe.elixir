package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirTyper;

/**
 * Integration tests for ElixirTyper - Testing Trophy focused
 * Verifies comprehensive type mapping functionality
 */
class TypeMappingIntegrationTest {
    public static function main() {
        trace("Running ElixirTyper Integration Tests...");
        
        testCompleteTypeSystemIntegration();
        testPhoenixEctoTypeMappings();
        testComplexGenericTypeMappings();
        testSpecGenerationVariety();
        testTypeDefinitionGeneration();
        testCachingAndPerformance();
        testEdgeCasesAndErrorHandling();
        testNoUnwantedAnyTypes();
        
        trace("✅ All ElixirTyper integration tests passed!");
    }
    
    /**
     * Test complete type system integration with real-world scenarios
     */
    static function testCompleteTypeSystemIntegration() {
        trace("TEST: Complete type system integration");
        
        var typer = new ElixirTyper();
        
        // Test comprehensive primitive mapping
        var primitiveTests = [
            {haxe: "Int", elixir: "integer()"},
            {haxe: "Float", elixir: "float()"},
            {haxe: "Bool", elixir: "boolean()"},
            {haxe: "String", elixir: "String.t()"},
            {haxe: "Void", elixir: "nil"}
        ];
        
        for (test in primitiveTests) {
            var result = typer.compileType(test.haxe);
            assertEqual(result, test.elixir, 'Type mapping: ${test.haxe} → ${test.elixir}');
        }
        
        // Test collection mapping
        assertEqual(typer.compileType("Array<String>"), "list(String.t())", "Array should map to list");
        assertEqual(typer.compileType("Map<String, Int>"), "%{String.t() => integer()}", "Map should map with proper syntax");
        
        // Test nullable mapping
        assertEqual(typer.compileType("Null<String>"), "String.t() | nil", "Nullable should add | nil");
        
        trace("✅ Complete type system integration test passed");
    }
    
    /**
     * Test Phoenix and Ecto specific type mappings
     */
    static function testPhoenixEctoTypeMappings() {
        trace("TEST: Phoenix and Ecto type mappings");
        
        var typer = new ElixirTyper();
        
        // Phoenix types
        assertEqual(typer.compileType("Conn"), "Plug.Conn.t()", "Conn should map to Plug.Conn.t()");
        assertEqual(typer.compileType("Socket"), "Phoenix.Socket.t()", "Socket should map to Phoenix.Socket.t()");
        assertEqual(typer.compileType("LiveView"), "Phoenix.LiveView.t()", "LiveView should map to Phoenix.LiveView.t()");
        
        // Ecto types
        assertEqual(typer.compileType("Schema"), "Ecto.Schema.t()", "Schema should map to Ecto.Schema.t()");
        assertEqual(typer.compileType("Changeset"), "Ecto.Changeset.t()", "Changeset should map to Ecto.Changeset.t()");
        assertEqual(typer.compileType("Query"), "Ecto.Query.t()", "Query should map to Ecto.Query.t()");
        
        trace("✅ Phoenix and Ecto type mappings test passed");
    }
    
    /**
     * Test complex generic type mappings
     */
    static function testComplexGenericTypeMappings() {
        trace("TEST: Complex generic type mappings");
        
        var typer = new ElixirTyper();
        
        // Nested generics
        assertEqual(typer.compileType("Array<Array<String>>"), "list(list(String.t()))", "Nested Array should work");
        assertEqual(typer.compileType("Null<Array<Int>>"), "list(integer()) | nil", "Nullable Array should work");
        assertEqual(typer.compileType("Map<String, Array<Int>>"), "%{String.t() => list(integer())}", "Map with Array value should work");
        
        // Complex nested nullable
        assertEqual(typer.compileType("Array<Null<String>>"), "list(String.t() | nil)", "Array of nullable should work");
        
        trace("✅ Complex generic type mappings test passed");
    }
    
    /**
     * Test @spec generation for various function signatures
     */
    static function testSpecGenerationVariety() {
        trace("TEST: @spec generation variety");
        
        var typer = new ElixirTyper();
        
        // Simple function spec
        var spec1 = typer.generateFunctionSpec("getValue", [], "String");
        assertTrue(spec1.indexOf("@spec get_value() :: String.t()") >= 0, "Simple function spec should work");
        
        // Function with parameters
        var spec2 = typer.generateFunctionSpec("processData", ["String", "Int", "Bool"], "Array<String>");
        assertTrue(spec2.indexOf("@spec process_data(String.t(), integer(), boolean()) :: list(String.t())") >= 0, 
                  "Multi-parameter function spec should work");
        
        // Function with complex types
        var spec3 = typer.generateFunctionSpec("complexFunc", ["Map<String, Int>", "Null<Array<String>>"], "Null<String>");
        assertTrue(spec3.indexOf("%{String.t() => integer()}") >= 0, "Complex parameter types should work");
        assertTrue(spec3.indexOf("String.t() | nil") >= 0, "Complex return types should work");
        
        trace("✅ @spec generation variety test passed");
    }
    
    /**
     * Test @type definition generation for structs and unions
     */
    static function testTypeDefinitionGeneration() {
        trace("TEST: @type definition generation");
        
        var typer = new ElixirTyper();
        
        // Struct type definition
        var fields = [
            {name: "userName", type: "String"},
            {name: "userAge", type: "Int"},
            {name: "isActive", type: "Bool"},
            {name: "metadata", type: "Map<String, String>"}
        ];
        
        var typeDef = typer.generateTypeDefinition("User", fields);
        
        assertTrue(typeDef.indexOf("@type t() :: %__MODULE__{") >= 0, "Should have proper struct type header");
        assertTrue(typeDef.indexOf("user_name: String.t()") >= 0, "Should convert field names to snake_case");
        assertTrue(typeDef.indexOf("user_age: integer()") >= 0, "Should map field types correctly");
        assertTrue(typeDef.indexOf("is_active: boolean()") >= 0, "Should handle boolean fields");
        assertTrue(typeDef.indexOf("metadata: %{String.t() => String.t()}") >= 0, "Should handle complex field types");
        
        // Union type definition
        var unionDef = typer.generateUnionTypeDefinition("Result", ["String", "Int", "Bool"]);
        assertTrue(unionDef.indexOf("@type t() ::") >= 0, "Union type should have proper header");
        assertTrue(unionDef.indexOf("String.t() |") >= 0, "Union should have mapped types");
        assertTrue(unionDef.indexOf("integer() |") >= 0, "Union should have pipe separators");
        assertTrue(unionDef.indexOf("boolean()") >= 0, "Union should end without pipe");
        
        trace("✅ @type definition generation test passed");
    }
    
    /**
     * Test caching and performance features
     */
    static function testCachingAndPerformance() {
        trace("TEST: Caching and performance");
        
        var typer = new ElixirTyper();
        
        // Test that caching works
        var result1 = typer.compileType("Array<String>");
        var result2 = typer.compileType("Array<String>"); // Should use cache
        
        assertEqual(result1, result2, "Cached results should be identical");
        
        // Test cache statistics
        var stats = typer.getCacheStats();
        assertTrue(stats.size > 0, "Cache should contain entries");
        assertTrue(stats.keys.indexOf("Array<String>") >= 0, "Cache should contain our test type");
        
        // Test cache clearing
        typer.clearCache();
        var statsAfter = typer.getCacheStats();
        assertEqual(statsAfter.size, 0, "Cache should be empty after clearing");
        
        trace("✅ Caching and performance test passed");
    }
    
    /**
     * Test edge cases and error handling
     */
    static function testEdgeCasesAndErrorHandling() {
        trace("TEST: Edge cases and error handling");
        
        var typer = new ElixirTyper();
        
        // Test null/empty input handling
        var nullResult = typer.compileType(null);
        assertEqual(nullResult, "term()", "Null input should return term()");
        
        var emptyResult = typer.compileType("");
        assertEqual(emptyResult, "term()", "Empty input should return term()");
        
        // Test malformed generic types
        var malformedResult = typer.compileType("Array<");
        assertTrue(malformedResult.length > 0, "Malformed types should not crash");
        
        // Test unknown custom types
        var unknownResult = typer.compileType("UnknownCustomType");
        assertEqual(unknownResult, "UnknownCustomType.t()", "Unknown types should become module references");
        
        // Test validation functions
        assertTrue(typer.isValidElixirType("String.t()"), "Should validate valid Elixir types");
        assertFalse(typer.isValidElixirType("InvalidType"), "Should reject invalid types");
        assertTrue(typer.isHaxeType("Array<Int>"), "Should detect Haxe types");
        assertFalse(typer.isHaxeType("String.t()"), "Should not detect Elixir types as Haxe");
        
        trace("✅ Edge cases and error handling test passed");
    }
    
    /**
     * Test that no unwanted any() types are generated per PRD requirements
     */
    static function testNoUnwantedAnyTypes() {
        trace("TEST: No unwanted any() types per PRD requirements");
        
        var typer = new ElixirTyper();
        
        // Test that concrete types don't map to any()
        var intType = typer.compileType("Int");
        assertFalse(intType.indexOf("any()") >= 0, "Int should not map to any()");
        
        var stringType = typer.compileType("String");
        assertFalse(stringType.indexOf("any()") >= 0, "String should not map to any()");
        
        var arrayType = typer.compileType("Array<String>");
        assertFalse(arrayType.indexOf("any()") >= 0, "Array<String> should not contain any()");
        
        // Verify we use more specific types
        assertEqual(stringType, "String.t()", "Should use specific String.t() not any()");
        assertEqual(intType, "integer()", "Should use specific integer() not any()");
        
        // Test that unknown types use term() rather than any()
        var unknownType = typer.compileType("SomeUnknownType");
        assertFalse(unknownType.indexOf("any()") >= 0, "Unknown types should not use any()");
        
        trace("✅ No unwanted any() types test passed");
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
     * Helper: Assert that condition is false with descriptive message
     */
    static function assertFalse(condition: Bool, message: String) {
        if (condition) {
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