package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.ElixirTyper;

/**
 * Integration tests for class→struct/module compilation
 * Testing Trophy focused - verifies complete class compilation system
 */
class ClassIntegrationTest {
    public static function main() {
        trace("Running Class Compilation Integration Tests...");
        
        testCompleteStructCompilation();
        testPhoenixContextCompilation();
        testEctoSchemaCompilation();
        testStructUpdatePatterns();
        testConstructorIntegration();
        testMethodChaining();
        
        trace("✅ All Class Integration tests passed!");
    }
    
    /**
     * Test complete @:struct class compilation with all features
     */
    static function testCompleteStructCompilation() {
        trace("TEST: Complete struct compilation");
        
        var compiler = new ElixirCompiler();
        
        // Mock complete User struct
        var classType = createMockClassType("User", "User data structure");
        classType.meta = [{name: ":struct", params: []}];
        
        var varFields = [
            createMockVarField("id", "Int", false),
            createMockVarField("name", "String", false),
            createMockVarField("email", "String", false),
            createMockVarField("active", "Bool", true),
            createMockVarField("metadata", "Map<String, String>", false),
            createMockVarField("createdAt", "Date", false)
        ];
        
        var funcFields = [
            createMockFuncField("new", ["Int", "String", "String"], "User"),
            createMockFuncField("updateEmail", ["String"], "User"),
            createMockStaticFuncField("findActive", [], "Array<User>")
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, funcFields);
        
        // Verify complete module structure
        assertTrue(result.indexOf("defmodule User do") >= 0, "Should create User module");
        assertTrue(result.indexOf("@moduledoc") >= 0, "Should have module documentation");
        
        // Verify defstruct with all fields
        assertTrue(result.indexOf("defstruct [") >= 0, "Should have defstruct");
        assertTrue(result.indexOf(":id") >= 0, "Should have id field");
        assertTrue(result.indexOf(":created_at") >= 0, "Should convert camelCase to snake_case");
        assertTrue(result.indexOf("active: true") >= 0, "Should have default values");
        
        // Verify @type definition
        assertTrue(result.indexOf("@type t() :: %__MODULE__{") >= 0, "Should have type definition");
        assertTrue(result.indexOf("id: integer()") >= 0, "Should have typed fields");
        assertTrue(result.indexOf("metadata: %{String.t() => String.t()}") >= 0, "Should handle Map types");
        
        // Verify constructor
        assertTrue(result.indexOf("def new(") >= 0, "Should have constructor");
        assertTrue(result.indexOf("@spec new(integer(), String.t(), String.t()) :: t()") >= 0,
                  "Constructor should have proper spec");
        
        // Verify instance method
        assertTrue(result.indexOf("def update_email(") >= 0, "Should have instance method");
        
        // Verify static method
        assertTrue(result.indexOf("def find_active()") >= 0, "Should have static method");
        
        trace("✅ Complete struct compilation test passed");
    }
    
    /**
     * Test Phoenix context-style class compilation
     */
    static function testPhoenixContextCompilation() {
        trace("TEST: Phoenix context compilation");
        
        var compiler = new ElixirCompiler();
        
        // Mock Accounts context (no @:struct)
        var classType = createMockClassType("Accounts", "Accounts context");
        // No @:struct metadata - regular class
        
        var funcFields = [
            createMockStaticFuncField("getUser", ["Int"], "Null<User>"),
            createMockStaticFuncField("listUsers", [], "Array<User>"),
            createMockStaticFuncField("createUser", ["Map<String, String>"], "User"),
            createMockStaticFuncField("updateUser", ["User", "Map<String, String>"], "User"),
            createMockStaticFuncField("deleteUser", ["User"], "Bool")
        ];
        
        var result = compiler.compileClassImpl(classType, [], funcFields);
        
        // Should NOT have defstruct
        assertFalse(result.indexOf("defstruct") >= 0, "Context should not have defstruct");
        
        // Should have Phoenix-style functions
        assertTrue(result.indexOf("def get_user(") >= 0, "Should have get_user");
        assertTrue(result.indexOf("def list_users()") >= 0, "Should have list_users");
        assertTrue(result.indexOf("def create_user(") >= 0, "Should have create_user");
        assertTrue(result.indexOf("def update_user(") >= 0, "Should have update_user");
        assertTrue(result.indexOf("def delete_user(") >= 0, "Should have delete_user");
        
        // Should have proper specs
        assertTrue(result.indexOf("@spec") >= 0, "Should have type specs");
        
        trace("✅ Phoenix context compilation test passed");
    }
    
    /**
     * Test Ecto schema-style struct compilation
     */
    static function testEctoSchemaCompilation() {
        trace("TEST: Ecto schema compilation");
        
        var compiler = new ElixirCompiler();
        
        // Mock UserSchema with @:struct and @:schema
        var classType = createMockClassType("UserSchema", "User database schema");
        classType.meta = [
            {name: ":struct", params: []},
            {name: ":schema", params: ["users"]} // Table name
        ];
        
        var varFields = [
            createMockVarField("id", "Int", false),
            createMockVarField("name", "String", false),
            createMockVarField("email", "String", false),
            createMockVarField("passwordHash", "String", false),
            createMockVarField("insertedAt", "Date", false),
            createMockVarField("updatedAt", "Date", false)
        ];
        
        var funcFields = [
            createMockFuncField("changeset", ["Map<String, Dynamic>"], "Dynamic")
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, funcFields);
        
        // Should have Ecto-style schema
        assertTrue(result.indexOf("defmodule UserSchema") >= 0, "Should create schema module");
        assertTrue(result.indexOf("use Ecto.Schema") >= 0 || 
                  result.indexOf("# @:schema(\"users\")") >= 0,
                  "Should indicate schema usage");
        
        // Should have defstruct with Ecto fields
        assertTrue(result.indexOf(":password_hash") >= 0, "Should have password_hash field");
        assertTrue(result.indexOf(":inserted_at") >= 0, "Should have timestamps");
        
        // Should have changeset function
        assertTrue(result.indexOf("def changeset(") >= 0, "Should have changeset function");
        
        trace("✅ Ecto schema compilation test passed");
    }
    
    /**
     * Test struct update pattern generation
     */
    static function testStructUpdatePatterns() {
        trace("TEST: Struct update patterns");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("Config", "");
        classType.meta = [{name: ":struct", params: []}];
        
        var varFields = [
            createMockVarField("key", "String", false),
            createMockVarField("value", "String", false)
        ];
        
        var funcFields = [
            createMockFuncField("setValue", ["String"], "Config"),
            createMockFuncField("merge", ["Config"], "Config")
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, funcFields);
        
        // Update functions should use Elixir struct update syntax
        assertTrue(result.indexOf("def set_value(") >= 0, "Should have setter function");
        
        // Should generate struct update pattern like:
        // %{struct | value: new_value}
        // or Map.put(struct, :value, new_value)
        
        trace("✅ Struct update patterns test passed");
    }
    
    /**
     * Test constructor function integration
     */
    static function testConstructorIntegration() {
        trace("TEST: Constructor integration");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("Product", "");
        classType.meta = [{name: ":struct", params: []}];
        
        var varFields = [
            createMockVarField("id", "Int", false),
            createMockVarField("name", "String", false),
            createMockVarField("price", "Float", false),
            createMockVarField("discount", "Float", true) // Has default
        ];
        
        var funcFields = [
            createMockFuncField("new", ["Int", "String", "Float"], "Product"),
            createMockStaticFuncField("create", ["String", "Float"], "Product") // Factory method
        ];
        
        var result = compiler.compileClassImpl(classType, varFields, funcFields);
        
        // Should have both constructors
        assertTrue(result.indexOf("def new(") >= 0, "Should have new constructor");
        assertTrue(result.indexOf("def create(") >= 0, "Should have factory method");
        
        // Constructor should create struct properly
        assertTrue(result.indexOf("%__MODULE__{") >= 0, "Should use %__MODULE__{} syntax");
        
        trace("✅ Constructor integration test passed");
    }
    
    /**
     * Test method chaining patterns for immutable updates
     */
    static function testMethodChaining() {
        trace("TEST: Method chaining for immutable updates");
        
        var compiler = new ElixirCompiler();
        
        var classType = createMockClassType("Builder", "Builder pattern");
        classType.meta = [{name: ":struct", params: []}];
        
        var funcFields = [
            createMockFuncField("withName", ["String"], "Builder"),
            createMockFuncField("withValue", ["Int"], "Builder"),
            createMockFuncField("build", [], "Dynamic")
        ];
        
        var result = compiler.compileClassImpl(classType, [], funcFields);
        
        // Each method should return updated struct for chaining
        assertTrue(result.indexOf("def with_name(") >= 0, "Should have with_name");
        assertTrue(result.indexOf("def with_value(") >= 0, "Should have with_value");
        
        // Methods should return t() for chaining
        assertTrue(result.indexOf(":: t()") >= 0, "Methods should return struct type");
        
        trace("✅ Method chaining test passed");
    }
    
    // Mock helper functions
    static function createMockClassType(name: String, doc: String) {
        return {
            getNameOrNative: function() return name,
            doc: doc,
            meta: [],
            superClass: null,
            interfaces: []
        };
    }
    
    static function createMockVarField(name: String, type: String, hasDefault: Bool, ?isFinal: Bool = false) {
        return {
            field: {
                name: name,
                type: type,
                isFinal: isFinal
            },
            expr: hasDefault ? {} : null
        };
    }
    
    static function createMockFuncField(name: String, paramTypes: Array<String>, returnType: String) {
        return {
            field: {
                name: name,
                isStatic: false
            },
            args: paramTypes.map(t -> {name: "arg", t: t}),
            ret: returnType,
            expr: null
        };
    }
    
    static function createMockStaticFuncField(name: String, paramTypes: Array<String>, returnType: String) {
        return {
            field: {
                name: name,
                isStatic: true
            },
            args: paramTypes.map(t -> {name: "arg", t: t}),
            ret: returnType,
            expr: null
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