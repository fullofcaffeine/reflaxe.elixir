import reflaxe.elixir.macro.ModuleMacro;

using StringTools;

/**
 * Test suite for @:module syntax sugar functionality
 * Follows TDD methodology with RED-GREEN-REFACTOR approach
 */
class ModuleSyntaxTest {
    
    /**
     * RED Phase Test: @:module classes should generate clean Elixir modules
     */
    public static function testModuleAnnotationBasic(): Bool {
        // This should fail initially - macro not implemented yet
        try {
            var result = ModuleMacro.processModuleAnnotation("TestModule", []);
            return result.contains("defmodule TestModule");
        } catch (e: Dynamic) {
            // Expected failure in RED phase
            return false;
        }
    }
    
    /**
     * RED Phase Test: Function definitions should work without public static boilerplate
     */
    public static function testFunctionWithoutPublicStatic(): Bool {
        try {
            var functions = [{
                name: "hello",
                args: ["name"],
                body: "\"Hello, #{name}!\"",
                isPrivate: false
            }];
            var result = ModuleMacro.processModuleFunctions(functions);
            return result.contains("def hello(name)");
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * RED Phase Test: Private functions should generate proper defp syntax
     */
    public static function testPrivateFunctionSyntax(): Bool {
        try {
            var functions = [{
                name: "internal_helper",
                args: ["data"],
                body: "process(data)",
                isPrivate: true
            }];
            var result = ModuleMacro.processModuleFunctions(functions);
            return result.contains("defp internal_helper(data)");
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * RED Phase Test: Pipe operators should function correctly within module context
     */
    public static function testPipeOperatorSupport(): Bool {
        try {
            var pipeExpr = "data |> process() |> format()";
            var result = ModuleMacro.processPipeOperator(pipeExpr);
            return result == "data |> process() |> format()";
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * RED Phase Test: Import and using statements should be handled properly
     */
    public static function testImportHandling(): Bool {
        try {
            var imports = ["String", "Map", "Process"];
            var result = ModuleMacro.processImports(imports);
            return result.contains("alias Elixir.String") && 
                   result.contains("alias Elixir.Map") &&
                   result.contains("alias Elixir.Process");
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * Integration test for complete @:module transformation
     */
    public static function testCompleteModuleTransformation(): Bool {
        try {
            var moduleData = {
                name: "UserService",
                imports: ["String", "Map"],
                functions: [
                    {
                        name: "create_user",
                        args: ["attrs"],
                        body: "attrs |> validate() |> create()",
                        isPrivate: false
                    },
                    {
                        name: "validate",
                        args: ["attrs"],
                        body: "Map.get(attrs, :name) != nil",
                        isPrivate: true
                    }
                ]
            };
            
            var result = ModuleMacro.transformModule(moduleData);
            return result.contains("defmodule UserService") &&
                   result.contains("def create_user(attrs)") &&
                   result.contains("defp validate(attrs)") &&
                   result.contains("alias Elixir.String");
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * Run all tests and report results
     */
    public static function main(): Void {
        var tests = [
            testModuleAnnotationBasic,
            testFunctionWithoutPublicStatic,
            testPrivateFunctionSyntax,
            testPipeOperatorSupport,
            testImportHandling,
            testCompleteModuleTransformation
        ];
        
        var passed = 0;
        var total = tests.length;
        
        trace("🔴 RED Phase: Running failing tests for @:module syntax sugar");
        
        for (test in tests) {
            if (test()) {
                passed++;
                trace("✅ PASS: " + test);
            } else {
                trace("❌ FAIL: " + test + " (Expected in RED phase)");
            }
        }
        
        trace('Results: ${passed}/${total} tests passing');
        
        if (passed == 0) {
            trace("🔴 RED Phase Complete: All tests failing as expected");
            trace("🔄 Next: Implement ModuleMacro to make tests pass (GREEN phase)");
        }
    }
}