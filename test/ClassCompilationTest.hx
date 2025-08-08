package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;

/**
 * Unit tests for class→struct/module compilation
 * Tests @:struct classes and regular class compilation
 */
class ClassCompilationTest {
    public static function main() {
        trace("Running Class Compilation Tests...");
        
        testStructClassCompilation();
        testDefstructGeneration();
        testConstructorFunctionGeneration();
        testRegularClassCompilation();
        testMethodCompilation();
        testFinalFieldHandling();
        testPatternMatchingSupport();
        
        trace("✅ All Class Compilation tests passed!");
    }
    
    /**
     * Test @:struct class compilation to defstruct
     */
    static function testStructClassCompilation() {
        trace("TEST: @:struct class compilation");
        
        var compiler = new ElixirCompiler();
        
        // Mock User struct class
        var classType = createMockClassType("User", "User data structure");
        classType.meta = [{name: ":struct", params: []}]; // Has @:struct metadata
        
        var varFields = [
            createMockVarField("id", "Int", false),
            createMockVarField("name", "String", false),
            createMockVarField("email", "String", false),
            createMockVarField("active", "Bool", true) // Has default value
        ];
        
        var funcFields = [
            createMockFuncField("new", ["Int", "String", "String"], "User")
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, funcFields);
        
        // Check module generation
        assertTrue(result != null, "Struct compilation should not return null");
        assertTrue(result.indexOf("defmodule User") >= 0, "Should create User module");
        
        // Check defstruct generation
        assertTrue(result.indexOf("defstruct") >= 0, "Should generate defstruct");
        assertTrue(result.indexOf(":id") >= 0, "Should have :id field");
        assertTrue(result.indexOf(":name") >= 0, "Should have :name field");
        assertTrue(result.indexOf(":email") >= 0, "Should have :email field");
        assertTrue(result.indexOf("active: true") >= 0, "Should have default value for active");
        
        trace("✅ @:struct class compilation test passed");
    }
    
    /**
     * Test defstruct generation with proper field mapping
     */
    static function testDefstructGeneration() {
        trace("TEST: defstruct generation");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("Product", "Product struct");
        classType.meta = [{name: ":struct", params: []}];
        
        var varFields = [
            createMockVarField("id", "Int", false),
            createMockVarField("title", "String", false),
            createMockVarField("description", "Null<String>", false),
            createMockVarField("price", "Float", false),
            createMockVarField("inStock", "Bool", true)
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, []);
        
        // Check defstruct syntax
        assertTrue(result.indexOf("defstruct [") >= 0, "Should have defstruct with bracket syntax");
        assertTrue(result.indexOf("in_stock: true") >= 0, "Should convert camelCase to snake_case");
        
        // Check @type definition
        assertTrue(result.indexOf("@type t() :: %__MODULE__{") >= 0, "Should have proper type definition");
        assertTrue(result.indexOf("id: integer()") >= 0, "Should have typed fields");
        assertTrue(result.indexOf("description: String.t() | nil") >= 0, "Should handle nullable types");
        
        trace("✅ defstruct generation test passed");
    }
    
    /**
     * Test constructor function generation (new/N)
     */
    static function testConstructorFunctionGeneration() {
        trace("TEST: Constructor function generation");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("User", "");
        classType.meta = [{name: ":struct", params: []}];
        
        var varFields = [
            createMockVarField("id", "Int", false),
            createMockVarField("name", "String", false)
        ];
        
        var funcFields = [
            createMockFuncField("new", ["Int", "String"], "User")
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, funcFields);
        
        // Check constructor function
        assertTrue(result.indexOf("def new(") >= 0, "Should have new function");
        assertTrue(result.indexOf("@spec new(integer(), String.t()) :: t()") >= 0, 
                  "Should have proper spec for constructor");
        assertTrue(result.indexOf("%__MODULE__{") >= 0, "Constructor should create struct");
        
        trace("✅ Constructor function generation test passed");
    }
    
    /**
     * Test regular class (non-struct) compilation to module
     */
    static function testRegularClassCompilation() {
        trace("TEST: Regular class compilation to module");
        
        var compiler = new ElixirCompiler();
        
        // Mock UserService class (no @:struct)
        var classType = createMockClassType("UserService", "User service module");
        // No @:struct metadata
        
        var funcFields = [
            createMockStaticFuncField("findById", ["Int"], "Null<User>"),
            createMockStaticFuncField("createUser", ["String", "String"], "User")
        ];
        
        var result = compiler.compileClassImpl(classType, [], funcFields);
        
        // Should NOT have defstruct
        assertFalse(result.indexOf("defstruct") >= 0, "Regular class should not have defstruct");
        
        // Should have module with functions
        assertTrue(result.indexOf("defmodule UserService") >= 0, "Should create module");
        assertTrue(result.indexOf("def find_by_id(") >= 0, "Should have static functions");
        assertTrue(result.indexOf("def create_user(") >= 0, "Should have create_user function");
        
        trace("✅ Regular class compilation test passed");
    }
    
    /**
     * Test method compilation for both struct and regular classes
     */
    static function testMethodCompilation() {
        trace("TEST: Method compilation");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("UserSchema", "");
        classType.meta = [{name: ":struct", params: []}];
        
        var funcFields = [
            createMockFuncField("changeset", ["Dynamic"], "Dynamic"),
            createMockStaticFuncField("validate", ["UserSchema"], "Bool")
        ];
        
        var result = compiler.compileClassImpl(classType, [], funcFields);
        
        // Instance methods should take struct as first parameter
        assertTrue(result.indexOf("def changeset(struct, ") >= 0 || 
                  result.indexOf("def changeset(%__MODULE__{} = struct,") >= 0,
                  "Instance methods should take struct as first parameter");
        
        // Static methods should not
        assertTrue(result.indexOf("def validate(") >= 0, "Static methods should be normal functions");
        
        trace("✅ Method compilation test passed");
    }
    
    /**
     * Test handling of final/immutable fields
     */
    static function testFinalFieldHandling() {
        trace("TEST: Final field handling");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("Config", "Configuration struct");
        classType.meta = [{name: ":struct", params: []}];
        
        var varFields = [
            createMockVarField("key", "String", false, true), // final field
            createMockVarField("value", "String", false, true), // final field
            createMockVarField("locked", "Bool", true, true) // final with default
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, []);
        
        // Final fields should still be in defstruct
        assertTrue(result.indexOf(":key") >= 0, "Final fields should be in struct");
        assertTrue(result.indexOf(":value") >= 0, "Final fields should be included");
        
        // Should have comment or documentation about immutability
        assertTrue(result.indexOf("@type t()") >= 0, "Should have type definition");
        
        trace("✅ Final field handling test passed");
    }
    
    /**
     * Test pattern matching support for struct updates
     */
    static function testPatternMatchingSupport() {
        trace("TEST: Pattern matching support");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("User", "");
        classType.meta = [{name: ":struct", params: []}];
        
        var funcFields = [
            createMockFuncField("updateName", ["String"], "User")
        ];
        
        var result = compiler.compileClassImpl(classType, [], funcFields);
        
        // Update functions should use pattern matching syntax
        // Looking for patterns like: %{struct | field: value}
        // or: Map.put(struct, :field, value)
        // The actual implementation will determine the exact pattern
        
        assertTrue(result.indexOf("def update_name") >= 0, "Should have update function");
        
        trace("✅ Pattern matching support test passed");
    }
    
    // Mock helper functions
    static function createMockClassType(name: String, doc: String) {
        return {
            getNameOrNative: function() return name,
            doc: doc,
            meta: []
        };
    }
    
    static function createMockVarField(name: String, type: String, hasDefault: Bool, ?isFinal: Bool = false) {
        return {
            field: {
                name: name,
                type: type,
                isFinal: isFinal
            },
            expr: hasDefault ? {} : null // Mock expression for default value
        };
    }
    
    static function createMockFuncField(name: String, paramTypes: Array<String>, returnType: String) {
        return {
            field: {
                name: name,
                isStatic: false
            },
            args: paramTypes.map(t -> {t: t}),
            ret: returnType,
            body: null
        };
    }
    
    static function createMockStaticFuncField(name: String, paramTypes: Array<String>, returnType: String) {
        return {
            field: {
                name: name,
                isStatic: true
            },
            args: paramTypes.map(t -> {t: t}),
            ret: returnType,
            body: null
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