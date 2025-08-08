import reflaxe.elixir.macro.ModuleMacro;
import reflaxe.elixir.macro.PipeOperator;

using StringTools;

/**
 * REFACTOR phase tests for @:module syntax sugar
 * Tests improved validation, error handling, and optimization
 */
class ModuleRefactorTest {
    
    public static function main(): Void {
        trace("🔵 REFACTOR Phase: Testing improved @:module implementation");
        
        var passed = 0;
        var total = 8;
        
        // Test 1: Module name validation - valid names
        try {
            var result = ModuleMacro.processModuleAnnotation("UserService", []);
            trace("✅ PASS: Valid module name accepted");
            passed++;
        } catch (e: Dynamic) {
            trace("❌ FAIL: Valid module name rejected: " + e);
        }
        
        // Test 2: Module name validation - invalid names
        try {
            ModuleMacro.processModuleAnnotation("userService", []);
            trace("❌ FAIL: Invalid module name should have been rejected");
        } catch (e: Dynamic) {
            trace("✅ PASS: Invalid module name correctly rejected");
            passed++;
        }
        
        // Test 3: Empty module name handling
        try {
            ModuleMacro.processModuleAnnotation("", []);
            trace("❌ FAIL: Empty module name should have been rejected");
        } catch (e: Dynamic) {
            trace("✅ PASS: Empty module name correctly rejected");
            passed++;
        }
        
        // Test 4: Null imports handling
        try {
            var result = ModuleMacro.processModuleAnnotation("TestModule", null);
            if (result.contains("defmodule TestModule")) {
                trace("✅ PASS: Null imports handled gracefully");
                passed++;
            } else {
                trace("❌ FAIL: Null imports not handled properly");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Null imports caused error: " + e);
        }
        
        // Test 5: Pipe operator validation - valid expression
        try {
            var isValid = PipeOperator.isValidPipeExpression("data |> process() |> format()");
            if (isValid) {
                trace("✅ PASS: Valid pipe expression recognized");
                passed++;
            } else {
                trace("❌ FAIL: Valid pipe expression rejected");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Pipe validation error: " + e);
        }
        
        // Test 6: Pipe operator validation - invalid expression
        try {
            var isValid = PipeOperator.isValidPipeExpression("data |> |> format()");
            if (!isValid) {
                trace("✅ PASS: Invalid pipe expression correctly rejected");
                passed++;
            } else {
                trace("❌ FAIL: Invalid pipe expression should have been rejected");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Pipe validation error: " + e);
        }
        
        // Test 7: Balanced parentheses validation
        try {
            var isValid = PipeOperator.isValidPipeExpression("data |> func(nested(call)) |> format()");
            if (isValid) {
                trace("✅ PASS: Balanced parentheses handled correctly");
                passed++;
            } else {
                trace("❌ FAIL: Balanced parentheses validation failed");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Parentheses validation error: " + e);
        }
        
        // Test 8: Nested module names
        try {
            var result = ModuleMacro.processModuleAnnotation("MyApp.UserService", ["String"]);
            if (result.contains("defmodule MyApp.UserService")) {
                trace("✅ PASS: Nested module names supported");
                passed++;
            } else {
                trace("❌ FAIL: Nested module names not supported");
            }
        } catch (e: Dynamic) {
            trace("❌ FAIL: Nested module name error: " + e);
        }
        
        trace('🔵 REFACTOR Phase Results: ${passed}/${total} tests passing');
        
        if (passed == total) {
            trace("🔵 REFACTOR Phase Complete: Implementation improved and optimized!");
            trace("✅ @:module syntax sugar implementation finished successfully!");
        } else {
            trace("⚠️  Some refactor tests failed - needs additional work");
        }
    }
}