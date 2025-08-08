package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirTyper;

/**
 * TDD Tests for ElixirTyper - Type mapping validation tests
 * These tests will initially fail until we implement the ElixirTyper
 */
class TypeMappingTest {
    public static function main() {
        trace("Running ElixirTyper TDD Tests...");
        
        testElixirTyperExists();
        testPrimitiveTypeMappings();
        testCollectionTypeMappings();
        testNullableTypeMappings();
        testSpecAnnotationGeneration();
        testTypeDefinitionGeneration();
        testComplexTypeMappings();
        testValidationUtilities();
        testNoAnyDynamicMappings();
        
        trace("✅ All ElixirTyper tests passed!");
    }
    
    static function testElixirTyperExists() {
        trace("TEST: ElixirTyper class exists and can be instantiated");
        try {
            var typer = new ElixirTyper();
            trace("✅ ElixirTyper instantiated successfully");
        } catch(e) {
            trace("❌ ElixirTyper does not exist: " + e);
            throw e;
        }
    }
    
    static function testPrimitiveTypeMappings() {
        trace("TEST: Primitive type mappings");
        try {
            var typer = new ElixirTyper();
            
            // Test basic primitive mappings as specified in requirements
            assertEqual(typer.compileType("Int"), "integer()", "Int should map to integer()");
            assertEqual(typer.compileType("Float"), "float()", "Float should map to float()");
            assertEqual(typer.compileType("Bool"), "boolean()", "Bool should map to boolean()");  
            assertEqual(typer.compileType("String"), "String.t()", "String should map to String.t()");
            assertEqual(typer.compileType("Void"), "nil", "Void should map to nil");
            
            trace("✅ Primitive type mappings test passed");
        } catch(e) {
            trace("❌ Primitive type mappings failed: " + e);
            throw e;
        }
    }
    
    static function testCollectionTypeMappings() {
        trace("TEST: Collection type mappings");
        try {
            var typer = new ElixirTyper();
            
            // Test collection mappings as specified in requirements
            assertEqual(typer.compileType("Array<String>"), "list(String.t())", "Array<T> should map to list(t)");
            assertEqual(typer.compileType("Array<Int>"), "list(integer())", "Array<Int> should map to list(integer())");
            
            assertEqual(typer.compileType("Map<String, Int>"), "%{String.t() => integer()}", "Map<K,V> should map to %{k => v}");
            assertEqual(typer.compileType("Map<Int, String>"), "%{integer() => String.t()}", "Map key/value types should be mapped");
            
            trace("✅ Collection type mappings test passed");
        } catch(e) {
            trace("❌ Collection type mappings failed: " + e);
            throw e;
        }
    }
    
    static function testNullableTypeMappings() {
        trace("TEST: Nullable type mappings");
        try {
            var typer = new ElixirTyper();
            
            // Test nullable mappings as specified: Null<T> → t | nil
            assertEqual(typer.compileType("Null<String>"), "String.t() | nil", "Null<T> should map to t | nil");
            assertEqual(typer.compileType("Null<Int>"), "integer() | nil", "Null<Int> should map to integer() | nil");
            assertEqual(typer.compileType("Null<Array<String>>"), "list(String.t()) | nil", "Nested nullable should work");
            
            trace("✅ Nullable type mappings test passed");
        } catch(e) {
            trace("❌ Nullable type mappings failed: " + e);
            throw e;
        }
    }
    
    static function testSpecAnnotationGeneration() {
        trace("TEST: @spec annotation generation");
        try {
            var typer = new ElixirTyper();
            
            // Test @spec generation for functions
            var funcSpec = typer.generateFunctionSpec("getUserData", ["String", "Int"], "Map<String, String>");
            assertTrue(funcSpec.indexOf("@spec get_user_data(String.t(), integer()) :: %{String.t() => String.t()}") >= 0, 
                "Should generate proper @spec annotation");
                
            // Test simple function spec
            var simpleSpec = typer.generateFunctionSpec("getValue", [], "String");
            assertTrue(simpleSpec.indexOf("@spec get_value() :: String.t()") >= 0,
                "Should handle functions with no parameters");
            
            trace("✅ @spec annotation generation test passed");
        } catch(e) {
            trace("❌ @spec annotation generation failed: " + e);
            throw e;
        }
    }
    
    static function testTypeDefinitionGeneration() {
        trace("TEST: @type definition generation");
        try {
            var typer = new ElixirTyper();
            
            // Test @type generation for custom types
            var typeFields = [
                {name: "name", type: "String"},
                {name: "age", type: "Int"},
                {name: "active", type: "Bool"}
            ];
            
            var typeDef = typer.generateTypeDefinition("User", typeFields);
            assertTrue(typeDef.indexOf("@type t() :: %__MODULE__{") >= 0, "Should generate @type structure");
            assertTrue(typeDef.indexOf("name: String.t()") >= 0, "Should include field types");
            assertTrue(typeDef.indexOf("age: integer()") >= 0, "Should map field types correctly");
            assertTrue(typeDef.indexOf("active: boolean()") >= 0, "Should handle all field types");
            
            trace("✅ @type definition generation test passed");
        } catch(e) {
            trace("❌ @type definition generation failed: " + e);
            throw e;
        }
    }
    
    static function testComplexTypeMappings() {
        trace("TEST: Complex type mappings");
        try {
            var typer = new ElixirTyper();
            
            // Test function types
            var funcType = typer.compileType("(String, Int) -> String");
            assertTrue(funcType.indexOf("(String.t(), integer() -> String.t())") >= 0 || 
                      funcType.indexOf("function") >= 0, "Should handle function types");
            
            // Test union types if supported
            var result = typer.compileType("Either<String, Int>"); // Custom handling may be needed
            assertTrue(result.length > 0, "Should handle complex custom types");
            
            trace("✅ Complex type mappings test passed");
        } catch(e) {
            trace("❌ Complex type mappings failed: " + e);
            throw e;
        }
    }
    
    static function testValidationUtilities() {
        trace("TEST: Type validation utilities");
        try {
            var typer = new ElixirTyper();
            
            // Test type validation
            assertTrue(typer.isValidElixirType("String.t()"), "Should validate Elixir types");
            assertTrue(typer.isValidElixirType("integer()"), "Should validate primitive types");
            assertTrue(typer.isValidElixirType("list(String.t())"), "Should validate collection types");
            assertFalse(typer.isValidElixirType("InvalidType"), "Should reject invalid types");
            
            // Test Haxe type detection
            assertTrue(typer.isHaxeType("String"), "Should detect Haxe types");
            assertTrue(typer.isHaxeType("Array<Int>"), "Should detect generic Haxe types");
            assertFalse(typer.isHaxeType("String.t()"), "Should not detect Elixir types as Haxe");
            
            trace("✅ Type validation utilities test passed");
        } catch(e) {
            trace("❌ Type validation utilities failed: " + e);
            throw e;
        }
    }
    
    static function testNoAnyDynamicMappings() {
        trace("TEST: No Any/Dynamic mappings per PRD requirements");
        try {
            var typer = new ElixirTyper();
            
            // Should avoid Dynamic/Any mappings except at interop boundaries
            var intType = typer.compileType("Int");
            assertFalse(intType.indexOf("any()") >= 0, "Should not use any() for concrete types");
            assertFalse(intType.indexOf("term()") >= 0, "Should not use term() for concrete types");
            
            // Test that we get specific types, not general ones
            var stringType = typer.compileType("String");
            assertEqual(stringType, "String.t()", "Should use specific String.t() not any()");
            
            trace("✅ No Any/Dynamic mappings test passed");
        } catch(e) {
            trace("❌ No Any/Dynamic mappings test failed: " + e);
            throw e;
        }
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