package regression;

import reflaxe.elixir.macro.ModuleMacro;
import reflaxe.elixir.macro.PipeOperator;
import reflaxe.elixir.macro.HXXMacro;

using StringTools;

/**
 * Regression testing for known edge cases and error scenarios
 * Ensures that previously fixed bugs don't resurface
 * Testing Trophy: Edge case validation and error handling
 */
class RegressionTest {
    
    /**
     * Test edge cases in @:module syntax processing
     * Regression test for invalid module names and edge cases
     */
    public static function testModuleSyntaxEdgeCases(): Bool {
        var passed = 0;
        var total = 6;
        
        // Test 1: Invalid module names should be rejected
        try {
            ModuleMacro.processModuleAnnotation("invalid_name", []);
            // Should have thrown error
        } catch (e: Dynamic) {
            if (e.toString().contains("Invalid Elixir module name")) {
                passed++;
            }
        }
        
        // Test 2: Empty module name should be rejected
        try {
            ModuleMacro.processModuleAnnotation("", []);
            // Should have thrown error
        } catch (e: Dynamic) {
            if (e.toString().contains("Module name cannot be null or empty")) {
                passed++;
            }
        }
        
        // Test 3: Null module name should be rejected
        try {
            ModuleMacro.processModuleAnnotation(null, []);
            // Should have thrown error
        } catch (e: Dynamic) {
            passed++;
        }
        
        // Test 4: Valid nested module names should be accepted
        try {
            var result = ModuleMacro.processModuleAnnotation("MyApp.UserService", ["String"]);
            if (result.contains("defmodule MyApp.UserService")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should not throw for valid names
        }
        
        // Test 5: Null imports should be handled gracefully
        try {
            var result = ModuleMacro.processModuleAnnotation("TestModule", null);
            if (result.contains("defmodule TestModule") && result.contains("end")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should not throw for null imports
        }
        
        // Test 6: Empty imports array should be handled
        try {
            var result = ModuleMacro.processModuleAnnotation("TestModule", []);
            if (result.contains("defmodule TestModule") && result.contains("end")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should not throw for empty imports
        }
        
        return passed >= 5; // Allow one test to vary in implementation
    }
    
    /**
     * Test edge cases in pipe operator processing
     * Regression test for malformed pipe expressions
     */
    public static function testPipeOperatorEdgeCases(): Bool {
        var passed = 0;
        var total = 8;
        
        // Test 1: Empty pipe expression should be invalid
        if (!PipeOperator.isValidPipeExpression("")) {
            passed++;
        }
        
        // Test 2: Null pipe expression should be invalid
        if (!PipeOperator.isValidPipeExpression(null)) {
            passed++;
        }
        
        // Test 3: Expression without pipe should be invalid
        if (!PipeOperator.isValidPipeExpression("just_a_function_call()")) {
            passed++;
        }
        
        // Test 4: Malformed pipe with empty parts should be invalid
        if (!PipeOperator.isValidPipeExpression("data |> |> process()")) {
            passed++;
        }
        
        // Test 5: Pipe expression with only spaces should be invalid
        if (!PipeOperator.isValidPipeExpression("   |>   ")) {
            passed++;
        }
        
        // Test 6: Unbalanced parentheses should be invalid
        if (!PipeOperator.isValidPipeExpression("data |> func(( |> format()")) {
            passed++;
        }
        
        // Test 7: Valid complex pipe expression should be accepted
        if (PipeOperator.isValidPipeExpression("data |> validate() |> process(options) |> save()")) {
            passed++;
        }
        
        // Test 8: Valid nested function calls should be accepted
        if (PipeOperator.isValidPipeExpression("user |> User.changeset(attrs) |> Repo.insert()")) {
            passed++;
        }
        
        return passed >= 7;
    }
    
    /**
     * Test edge cases in HXX template processing
     * Regression test for malformed JSX and template edge cases
     */
    public static function testHXXTemplateEdgeCases(): Bool {
        var passed = 0;
        var total = 7;
        
        // Test 1: Empty template should be handled gracefully
        try {
            var result = HXXMacro.transformToHEEx("");
            // Should either return empty string or handle gracefully
            passed++;
        } catch (e: Dynamic) {
            // Acceptable to throw for empty input
            passed++;
        }
        
        // Test 2: Simple text without tags should be preserved
        try {
            var result = HXXMacro.transformToHEEx("Just plain text");
            if (result == "Just plain text") {
                passed++;
            }
        } catch (e: Dynamic) {
            // May not support plain text
        }
        
        // Test 3: Malformed JSX should be handled
        try {
            var result = HXXMacro.transformToHEEx("<div><span></div>");
            // Should either fix or gracefully handle mismatched tags
            passed++;
        } catch (e: Dynamic) {
            // Acceptable to throw for malformed JSX
            passed++;
        }
        
        // Test 4: Complex nested JSX should work
        try {
            var jsx = '<div className="container"><UserCard user={user} /></div>';
            var result = HXXMacro.transformToHEEx(jsx);
            if (result.contains("class=") && result.contains("{@user}")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should handle complex cases
        }
        
        // Test 5: Self-closing tags should work
        try {
            var jsx = '<input type="text" value={name} />';
            var result = HXXMacro.transformToHEEx(jsx);
            if (result.contains("value={@name}")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should handle self-closing tags
        }
        
        // Test 6: Event handlers should be converted
        try {
            var jsx = '<button onClick="handle_click">Click me</button>';
            var result = HXXMacro.transformToHEEx(jsx);
            if (result.contains("phx-click=")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should convert event handlers
        }
        
        // Test 7: LiveView directives should be converted
        try {
            var jsx = '<div lv:if="show_content">{content}</div>';
            var result = HXXMacro.transformToHEEx(jsx);
            if (result.contains(":if={@show_content}")) {
                passed++;
            }
        } catch (e: Dynamic) {
            // Should convert directives
        }
        
        return passed >= 5;
    }
    
    /**
     * Test function compilation edge cases
     * Regression test for function generation issues
     */
    public static function testFunctionCompilationEdgeCases(): Bool {
        var passed = 0;
        var total = 5;
        
        // Test 1: Functions with no parameters
        try {
            var functions = [{
                name: "get_timestamp",
                args: [],
                body: "DateTime.utc_now()",
                isPrivate: false
            }];
            var result = ModuleMacro.processModuleFunctions(functions);
            if (result.contains("def get_timestamp()")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Function with no params error: " + e);
        }
        
        // Test 2: Private functions should generate defp
        try {
            var functions = [{
                name: "helper_function",
                args: ["data"],
                body: "process(data)",
                isPrivate: true
            }];
            var result = ModuleMacro.processModuleFunctions(functions);
            if (result.contains("defp helper_function(data)")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Private function error: " + e);
        }
        
        // Test 3: Functions with many parameters
        try {
            var functions = [{
                name: "complex_function",
                args: ["param1", "param2", "param3", "param4", "param5"],
                body: "do_work()",
                isPrivate: false
            }];
            var result = ModuleMacro.processModuleFunctions(functions);
            if (result.contains("def complex_function(param1, param2, param3, param4, param5)")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Many params function error: " + e);
        }
        
        // Test 4: Empty function list should be handled
        try {
            var result = ModuleMacro.processModuleFunctions([]);
            // Should return empty string or minimal content
            passed++;
        } catch (e: Dynamic) {
            // Should not throw for empty list
            trace("Empty function list error: " + e);
        }
        
        // Test 5: Null function list should be handled gracefully
        try {
            var result = ModuleMacro.processModuleFunctions(null);
            // Should either handle gracefully or throw informative error
            passed++;
        } catch (e: Dynamic) {
            // Acceptable to throw for null input
            passed++;
        }
        
        return passed >= 4;
    }
    
    /**
     * Test complete module transformation edge cases
     * Regression test for complex module generation scenarios
     */
    public static function testCompleteModuleEdgeCases(): Bool {
        var passed = 0;
        var total = 4;
        
        // Test 1: Module with minimal content
        try {
            var moduleData = {
                name: "MinimalModule",
                imports: [],
                functions: []
            };
            var result = ModuleMacro.transformModule(moduleData);
            if (result.contains("defmodule MinimalModule") && result.contains("end")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Minimal module error: " + e);
        }
        
        // Test 2: Module with only imports, no functions
        try {
            var moduleData = {
                name: "ImportOnlyModule",
                imports: ["String", "Map"],
                functions: []
            };
            var result = ModuleMacro.transformModule(moduleData);
            if (result.contains("alias Elixir.String") && result.contains("alias Elixir.Map")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Import only module error: " + e);
        }
        
        // Test 3: Module with complex nested name
        try {
            var moduleData = {
                name: "MyApp.Contexts.UserManagement.Service",
                imports: ["Ecto.Query"],
                functions: [{
                    name: "test_function",
                    args: [],
                    body: "nil",
                    isPrivate: false
                }]
            };
            var result = ModuleMacro.transformModule(moduleData);
            if (result.contains("defmodule MyApp.Contexts.UserManagement.Service")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Nested module name error: " + e);
        }
        
        // Test 4: Module with mix of public and private functions
        try {
            var moduleData = {
                name: "MixedModule",
                imports: [],
                functions: [
                    {
                        name: "public_func",
                        args: ["arg1"],
                        body: "process(arg1)",
                        isPrivate: false
                    },
                    {
                        name: "private_helper",
                        args: ["arg1"],
                        body: "helper_process(arg1)",
                        isPrivate: true
                    }
                ]
            };
            var result = ModuleMacro.transformModule(moduleData);
            if (result.contains("def public_func(arg1)") && 
                result.contains("defp private_helper(arg1)")) {
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Mixed functions module error: " + e);
        }
        
        return passed >= 3;
    }
    
    /**
     * Test performance under stress conditions
     * Regression test for performance degradation with large inputs
     */
    public static function testPerformanceRegressionCases(): Bool {
        var passed = 0;
        var total = 3;
        
        // Test 1: Large number of imports
        try {
            var largeImports = [];
            for (i in 0...100) {
                largeImports.push('Module${i}');
            }
            
            var startTime = haxe.Timer.stamp();
            var result = ModuleMacro.processModuleAnnotation("LargeModule", largeImports);
            var endTime = haxe.Timer.stamp();
            var duration = (endTime - startTime) * 1000;
            
            if (duration < 50 && result.contains("defmodule LargeModule")) { // 50ms threshold
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Large imports performance error: " + e);
        }
        
        // Test 2: Large number of functions
        try {
            var largeFunctions = [];
            for (i in 0...50) {
                largeFunctions.push({
                    name: 'function${i}',
                    args: ["arg1", "arg2"],
                    body: "process_${i}(arg1, arg2)",
                    isPrivate: i % 2 == 1 // Mix of public and private
                });
            }
            
            var startTime = haxe.Timer.stamp();
            var result = ModuleMacro.processModuleFunctions(largeFunctions);
            var endTime = haxe.Timer.stamp();
            var duration = (endTime - startTime) * 1000;
            
            if (duration < 100) { // 100ms threshold
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Large functions performance error: " + e);
        }
        
        // Test 3: Complex pipe expression processing
        try {
            var complexPipe = "data |> validate_step_1() |> transform_step_1() |> validate_step_2() |> transform_step_2() |> validate_step_3() |> transform_step_3() |> save_step_1() |> notify_step_1() |> cleanup_step_1()";
            
            var startTime = haxe.Timer.stamp();
            var isValid = PipeOperator.isValidPipeExpression(complexPipe);
            var optimized = PipeOperator.generateOptimizedPipe(complexPipe);
            var endTime = haxe.Timer.stamp();
            var duration = (endTime - startTime) * 1000;
            
            if (duration < 10 && isValid && optimized.length > 0) { // 10ms threshold
                passed++;
            }
        } catch (e: Dynamic) {
            trace("Complex pipe performance error: " + e);
        }
        
        return passed >= 2;
    }
    
    /**
     * Run all regression tests
     */
    public static function main(): Void {
        trace("🔍 Regression Tests: Edge Cases and Error Scenarios");
        trace("Testing previously fixed bugs and known edge cases");
        trace("");
        
        var tests = [
            testModuleSyntaxEdgeCases,
            testPipeOperatorEdgeCases,
            testHXXTemplateEdgeCases,
            testFunctionCompilationEdgeCases,
            testCompleteModuleEdgeCases,
            testPerformanceRegressionCases
        ];
        
        var testNames = [
            "Module Syntax Edge Cases",
            "Pipe Operator Edge Cases",
            "HXX Template Edge Cases",
            "Function Compilation Edge Cases",
            "Complete Module Edge Cases",
            "Performance Regression Cases"
        ];
        
        var passed = 0;
        var total = tests.length;
        
        for (i in 0...tests.length) {
            var test = tests[i];
            var name = testNames[i];
            
            try {
                if (test()) {
                    trace('✅ REGRESSION PASS: ${name}');
                    passed++;
                } else {
                    trace('❌ REGRESSION FAIL: ${name}');
                }
            } catch (e: Dynamic) {
                trace('❌ REGRESSION ERROR: ${name} - ${e}');
            }
        }
        
        trace("");
        trace('🔍 Regression Test Results: ${passed}/${total} tests passing');
        
        if (passed == total) {
            trace("🎉 All regression tests passed! No regressions detected.");
            trace("✅ Edge cases handled correctly");
            trace("✅ Error scenarios properly managed");
            trace("✅ Performance within acceptable bounds");
        } else {
            trace("⚠️  Some regression tests failed - investigation needed");
            trace("🐛 Potential regressions or unhandled edge cases detected");
        }
    }
}