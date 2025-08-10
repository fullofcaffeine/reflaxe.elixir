package test;

#if (macro || reflaxe_runtime)

import utest.Test;
import utest.Assert;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.ElixirTyper;

/**
 * Integration tests for class→struct/module compilation
 * Testing Trophy focused - verifies complete class compilation system
 */
class ClassIntegrationTest extends Test {
    
    /**
     * Test complete @:struct class compilation with all features
     */
    public function testCompleteStructCompilation() {
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
        Assert.isTrue(result.indexOf("defmodule User do") >= 0, "Should create User module");
        Assert.isTrue(result.indexOf("@moduledoc") >= 0, "Should have module documentation");
        
        // Verify defstruct with all fields
        Assert.isTrue(result.indexOf("defstruct [") >= 0, "Should have defstruct");
        Assert.isTrue(result.indexOf(":id") >= 0, "Should have id field");
        Assert.isTrue(result.indexOf(":created_at") >= 0, "Should convert camelCase to snake_case");
        Assert.isTrue(result.indexOf("active: true") >= 0, "Should have default values");
        
        // Verify @type definition
        Assert.isTrue(result.indexOf("@type t() :: %__MODULE__{") >= 0, "Should have type definition");
        Assert.isTrue(result.indexOf("id: integer()") >= 0, "Should have typed fields");
        Assert.isTrue(result.indexOf("metadata: %{String.t() => String.t()}") >= 0, "Should handle Map types");
        
        // Verify constructor
        Assert.isTrue(result.indexOf("def new(") >= 0, "Should have constructor");
        Assert.isTrue(result.indexOf("@spec new(integer(), String.t(), String.t()) :: t()") >= 0, "Constructor should have proper spec");
        
        // Verify instance method
        Assert.isTrue(result.indexOf("def update_email(") >= 0, "Should have instance method");
        
        // Verify static method
        Assert.isTrue(result.indexOf("def find_active()") >= 0, "Should have static method");
    }
    
    /**
     * Test Phoenix context-style class compilation
     */
    public function testPhoenixContextCompilation() {
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
        Assert.isFalse(result.indexOf("defstruct") >= 0, "Context should not have defstruct");
        
        // Should have Phoenix-style functions
        Assert.isTrue(result.indexOf("def get_user(") >= 0, "Should have get_user");
        Assert.isTrue(result.indexOf("def list_users()") >= 0, "Should have list_users");
        Assert.isTrue(result.indexOf("def create_user(") >= 0, "Should have create_user");
        Assert.isTrue(result.indexOf("def update_user(") >= 0, "Should have update_user");
        Assert.isTrue(result.indexOf("def delete_user(") >= 0, "Should have delete_user");
        
        // Should have proper specs
        Assert.isTrue(result.indexOf("@spec") >= 0, "Should have type specs");
    }
    
    /**
     * Test Ecto schema-style struct compilation
     */
    public function testEctoSchemaCompilation() {
        
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
        Assert.isTrue(result.indexOf("defmodule UserSchema") >= 0, "Should create schema module");
        Assert.isTrue(result.indexOf("use Ecto.Schema") >= 0 || 
                  result.indexOf("# @:schema(\"users\")") >= 0, "Should indicate schema usage");
        
        // Should have defstruct with Ecto fields
        Assert.isTrue(result.indexOf(":password_hash") >= 0, "Should have password_hash field");
        Assert.isTrue(result.indexOf(":inserted_at") >= 0, "Should have timestamps");
        
        // Should have changeset function
        Assert.isTrue(result.indexOf("def changeset(") >= 0, "Should have changeset function");
        
    }
    
    /**
     * Test struct update pattern generation
     */
    public function testStructUpdatePatterns() {
        
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
        Assert.isTrue(result.indexOf("def set_value(") >= 0, "Should have setter function");
        
        // Should generate struct update pattern like:
        // %{struct | value: new_value}
        // or Map.put(struct, :value, new_value)
    }
    
    /**
     * Test constructor function integration
     */
    public function testConstructorIntegration() {
        
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
        Assert.isTrue(result.indexOf("def new(") >= 0, "Should have new constructor");
        Assert.isTrue(result.indexOf("def create(") >= 0, "Should have factory method");
        
        // Constructor should create struct properly
        Assert.isTrue(result.indexOf("%__MODULE__{") >= 0, "Should use %__MODULE__{} syntax");
        
    }
    
    /**
     * Test method chaining patterns for immutable updates
     */
    public function testMethodChaining() {
        
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
        Assert.isTrue(result.indexOf("def with_name(") >= 0, "Should have with_name");
        Assert.isTrue(result.indexOf("def with_value(") >= 0, "Should have with_value");
        
        // Methods should return t() for chaining
        Assert.isTrue(result.indexOf(":: t()") >= 0, "Methods should return struct type");
        
    }
    
    // Mock helper functions
    function createMockClassType(name: String, doc: String) {
        return {
            getNameOrNative: function() return name,
            doc: doc,
            meta: [],
            superClass: null,
            interfaces: []
        };
    }
    
    function createMockVarField(name: String, type: String, hasDefault: Bool, ?isFinal: Bool = false) {
        return {
            field: {
                name: name,
                type: type,
                isFinal: isFinal
            },
            expr: hasDefault ? {} : null
        };
    }
    
    function createMockFuncField(name: String, paramTypes: Array<String>, returnType: String) {
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
    
    function createMockStaticFuncField(name: String, paramTypes: Array<String>, returnType: String) {
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
}

#end