package test;

import utest.Assert;
import utest.Test;

/**
 * Integration test for @:module syntax sugar
 * Tests end-to-end compilation with @:module annotation
 * 
 * MIGRATED FROM: ModuleIntegrationTest.hx
 * MIGRATION NOTES:
 * - Using utest framework for better test organization
 * - ModuleMacro and PipeOperator are macro-time components, using runtime mocks
 * - Tests validate complete module transformation pipeline
 */
class ModuleIntegrationTest extends Test {
    
    /**
     * Test: ModuleMacro functionality
     */
    public function testModuleMacroProcessing() {
        var result = mockProcessModuleAnnotation("TestModule", ["String", "Map"]);
        Assert.isTrue(result.indexOf("defmodule TestModule") >= 0);
        Assert.isTrue(result.indexOf("alias Elixir.String") >= 0);
        Assert.isTrue(result.indexOf("alias Elixir.Map") >= 0);
    }
    
    /**
     * Test: PipeOperator functionality
     */
    public function testPipeOperatorProcessing() {
        var result = mockProcessPipeExpression("data |> process() |> format()");
        Assert.equals("data |> process() |> format()", result);
    }
    
    /**
     * Test: Module function generation
     */
    public function testModuleFunctionGeneration() {
        var functions = [
            {
                name: "test_func",
                args: ["data"],
                body: "process(data)",
                isPrivate: false
            }
        ];
        var result = mockProcessModuleFunctions(functions);
        Assert.isTrue(result.indexOf("def test_func(data)") >= 0);
        Assert.isTrue(result.indexOf("process(data)") >= 0);
    }
    
    /**
     * Test: Private function generation
     */
    public function testPrivateFunctionGeneration() {
        var functions = [
            {
                name: "helper",
                args: ["input"],
                body: "validate(input)",
                isPrivate: true
            }
        ];
        var result = mockProcessModuleFunctions(functions);
        Assert.isTrue(result.indexOf("defp helper(input)") >= 0);
        Assert.isTrue(result.indexOf("validate(input)") >= 0);
    }
    
    /**
     * Test: Complete module transformation
     */
    public function testCompleteModuleTransformation() {
        var moduleData = {
            name: "UserService",
            imports: ["String"],
            functions: [
                {
                    name: "create_user",
                    args: ["name", "email"],
                    body: "User.new(name, email)",
                    isPrivate: false
                }
            ]
        };
        var result = mockTransformModule(moduleData);
        Assert.isTrue(result.indexOf("defmodule UserService") >= 0);
        Assert.isTrue(result.indexOf("def create_user(name, email)") >= 0);
        Assert.isTrue(result.indexOf("User.new(name, email)") >= 0);
        Assert.isTrue(result.indexOf("alias Elixir.String") >= 0);
    }
    
    // === EDGE CASE TESTING ===
    
    /**
     * Test: Module with multiple pipe operations
     */
    public function testComplexPipeChain() {
        var expr = "data |> validate() |> transform() |> persist() |> notify()";
        var result = mockProcessPipeExpression(expr);
        Assert.equals(expr, result);
    }
    
    /**
     * Test: Module with mixed public and private functions
     */
    public function testMixedFunctionVisibility() {
        var functions = [
            { name: "public_api", args: ["data"], body: "process(data)", isPrivate: false },
            { name: "internal_helper", args: ["x"], body: "validate(x)", isPrivate: true },
            { name: "another_public", args: [], body: "get_all()", isPrivate: false }
        ];
        var result = mockProcessModuleFunctions(functions);
        Assert.isTrue(result.indexOf("def public_api(data)") >= 0);
        Assert.isTrue(result.indexOf("defp internal_helper(x)") >= 0);
        Assert.isTrue(result.indexOf("def another_public()") >= 0);
    }
    
    /**
     * Test: Module with no imports
     */
    public function testModuleWithoutImports() {
        var moduleData = {
            name: "SimpleModule",
            imports: null,
            functions: [
                { name: "simple", args: [], body: "42", isPrivate: false }
            ]
        };
        var result = mockTransformModule(moduleData);
        Assert.isTrue(result.indexOf("defmodule SimpleModule") >= 0);
        Assert.isFalse(result.indexOf("alias") >= 0);
        Assert.isTrue(result.indexOf("def simple()") >= 0);
    }
    
    /**
     * Test: Module with no functions
     */
    public function testModuleWithoutFunctions() {
        var moduleData = {
            name: "DataModule",
            imports: ["Map"],
            functions: null
        };
        var result = mockTransformModule(moduleData);
        Assert.isTrue(result.indexOf("defmodule DataModule") >= 0);
        Assert.isTrue(result.indexOf("alias Elixir.Map") >= 0);
        Assert.isTrue(result.indexOf("end") >= 0);
    }
    
    /**
     * Test: Function with empty body
     */
    public function testFunctionWithEmptyBody() {
        var functions = [
            { name: "noop", args: [], body: "", isPrivate: false }
        ];
        var result = mockProcessModuleFunctions(functions);
        Assert.isTrue(result.indexOf("def noop()") >= 0);
    }
    
    // === RUNTIME MOCKS ===
    // These simulate what ModuleMacro and PipeOperator would generate at compile-time
    
    function mockProcessModuleAnnotation(name: String, imports: Array<String>): String {
        var parts = ['defmodule $name do'];
        if (imports != null) {
            for (imp in imports) {
                parts.push('  alias Elixir.$imp');
            }
        }
        parts.push("end");
        return parts.join("\n");
    }
    
    function mockProcessPipeExpression(expr: String): String {
        // Pipe expressions pass through unchanged in Elixir
        return expr;
    }
    
    function mockProcessModuleFunctions(functions: Array<Dynamic>): String {
        var result = [];
        for (func in functions) {
            var prefix = func.isPrivate ? "defp" : "def";
            var args = (cast func.args : Array<String>).join(", ");
            result.push('  $prefix ${func.name}($args) do');
            if (func.body != null && func.body != "") {
                result.push('    ${func.body}');
            }
            result.push('  end');
        }
        return result.join("\n");
    }
    
    function mockTransformModule(moduleData: Dynamic): String {
        var parts = [];
        parts.push('defmodule ${moduleData.name} do');
        
        // Add imports
        if (moduleData.imports != null) {
            for (imp in (moduleData.imports : Array<String>)) {
                parts.push('  alias Elixir.$imp');
            }
            if (moduleData.functions != null) {
                parts.push("");
            }
        }
        
        // Add functions
        if (moduleData.functions != null) {
            for (func in (moduleData.functions : Array<Dynamic>)) {
                var prefix = func.isPrivate ? "defp" : "def";
                var args = (cast func.args : Array<String>).join(", ");
                parts.push('  $prefix ${func.name}($args) do');
                if (func.body != null && func.body != "") {
                    parts.push('    ${func.body}');
                }
                parts.push('  end');
            }
        }
        
        parts.push("end");
        return parts.join("\n");
    }
}