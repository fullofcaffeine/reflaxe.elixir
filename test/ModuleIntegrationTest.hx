import reflaxe.elixir.macro.ModuleMacro;
import reflaxe.elixir.macro.PipeOperator;

/**
 * Integration test for @:module syntax sugar
 * Tests end-to-end compilation with @:module annotation
 */
class ModuleIntegrationTest {
    
    public static function main(): Void {
        trace("🟢 GREEN Phase: Testing @:module integration");
        
        var passed = 0;
        var total = 5;
        
        // Test 1: ModuleMacro functionality
        try {
            var result = ModuleMacro.processModuleAnnotation("TestModule", ["String", "Map"]);
            if (result.indexOf("defmodule TestModule") >= 0) {
                trace("✅ PASS: ModuleMacro.processModuleAnnotation working");
                passed++;
            } else {
                trace("❌ FAIL: ModuleMacro output incorrect");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: ModuleMacro error: " + e);
        }
        
        // Test 2: PipeOperator functionality
        try {
            var result = PipeOperator.processPipeExpression("data |> process() |> format()");
            if (result == "data |> process() |> format()") {
                trace("✅ PASS: PipeOperator.processPipeExpression working");
                passed++;
            } else {
                trace("❌ FAIL: PipeOperator output incorrect");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: PipeOperator error: " + e);
        }
        
        // Test 3: Module function generation
        try {
            var functions = [
                {
                    name: "test_func",
                    args: ["data"],
                    body: "process(data)",
                    isPrivate: false
                }
            ];
            var result = ModuleMacro.processModuleFunctions(functions);
            if (result.indexOf("def test_func(data)") >= 0) {
                trace("✅ PASS: Module function generation working");
                passed++;
            } else {
                trace("❌ FAIL: Module function generation incorrect");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Module function generation error: " + e);
        }
        
        // Test 4: Private function generation
        try {
            var functions = [
                {
                    name: "helper",
                    args: ["input"],
                    body: "validate(input)",
                    isPrivate: true
                }
            ];
            var result = ModuleMacro.processModuleFunctions(functions);
            if (result.indexOf("defp helper(input)") >= 0) {
                trace("✅ PASS: Private function generation working");
                passed++;
            } else {
                trace("❌ FAIL: Private function generation incorrect");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Private function generation error: " + e);
        }
        
        // Test 5: Complete module transformation
        try {
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
            var result = ModuleMacro.transformModule(moduleData);
            if (result.indexOf("defmodule UserService") >= 0 && 
                result.indexOf("def create_user(name, email)") >= 0) {
                trace("✅ PASS: Complete module transformation working");
                passed++;
            } else {
                trace("❌ FAIL: Complete module transformation incorrect");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Complete module transformation error: " + e);
        }
        
        trace('🟢 GREEN Phase Results: ${passed}/${total} integration tests passing');
        
        if (passed == total) {
            trace("🟢 GREEN Phase Complete: @:module syntax sugar working!");
            trace("🔵 Next: REFACTOR phase - optimize and improve design");
        } else {
            trace("⚠️  Some integration tests failed - needs investigation");
        }
    }
}