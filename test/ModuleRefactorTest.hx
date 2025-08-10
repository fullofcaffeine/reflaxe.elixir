package test;

import utest.Assert;
import utest.Test;
using StringTools;

/**
 * REFACTOR phase tests for @:module syntax sugar
 * Tests improved validation, error handling, and optimization
 * 
 * MIGRATED FROM: ModuleRefactorTest.hx
 * MIGRATION NOTES:
 * - Using utest framework for better test structure and assertions
 * - ModuleMacro and PipeOperator are macro-time components, using runtime mocks
 * - Tests validate validation logic, error handling, and edge cases
 */
class ModuleRefactorTest extends Test {
    
    /**
     * Test: Module name validation - valid names
     */
    public function testValidModuleName() {
        var result = mockProcessModuleAnnotationWithValidation("UserService", []);
        Assert.isTrue(result.indexOf("defmodule UserService") >= 0);
    }
    
    /**
     * Test: Module name validation - invalid names (should start with uppercase)
     */
    public function testInvalidModuleName() {
        try {
            mockProcessModuleAnnotationWithValidation("userService", []);
            Assert.fail("Invalid module name should have been rejected");
        } catch (e: String) {
            Assert.equals("Module name must start with uppercase letter", e);
        }
    }
    
    /**
     * Test: Empty module name handling
     */
    public function testEmptyModuleName() {
        try {
            mockProcessModuleAnnotationWithValidation("", []);
            Assert.fail("Empty module name should have been rejected");
        } catch (e: String) {
            Assert.equals("Module name cannot be empty", e);
        }
    }
    
    /**
     * Test: Null imports handling
     */
    public function testNullImportsHandling() {
        var result = mockProcessModuleAnnotationWithValidation("TestModule", null);
        Assert.isTrue(result.indexOf("defmodule TestModule") >= 0);
        // Should not contain any alias statements
        Assert.isFalse(result.indexOf("alias") >= 0);
    }
    
    /**
     * Test: Pipe operator validation - valid expression
     */
    public function testValidPipeExpression() {
        var isValid = mockIsValidPipeExpression("data |> process() |> format()");
        Assert.isTrue(isValid);
    }
    
    /**
     * Test: Pipe operator validation - invalid expression (empty pipe)
     */
    public function testInvalidPipeExpression() {
        var isValid = mockIsValidPipeExpression("data |> |> format()");
        Assert.isFalse(isValid);
    }
    
    /**
     * Test: Balanced parentheses validation
     */
    public function testBalancedParentheses() {
        var isValid = mockIsValidPipeExpression("data |> func(nested(call)) |> format()");
        Assert.isTrue(isValid);
    }
    
    /**
     * Test: Nested module names
     */
    public function testNestedModuleNames() {
        var result = mockProcessModuleAnnotationWithValidation("MyApp.UserService", ["String"]);
        Assert.isTrue(result.indexOf("defmodule MyApp.UserService") >= 0);
        Assert.isTrue(result.indexOf("alias Elixir.String") >= 0);
    }
    
    // === EDGE CASE TESTING ===
    
    /**
     * Test: Module name with reserved keywords
     */
    public function testModuleNameWithReservedKeywords() {
        // Should handle Elixir reserved words properly
        try {
            mockProcessModuleAnnotationWithValidation("And", []);
            Assert.fail("Reserved keyword 'And' should be rejected");
        } catch (e: String) {
            Assert.isTrue(e.indexOf("reserved") >= 0);
        }
    }
    
    /**
     * Test: Very long module names
     */
    public function testVeryLongModuleName() {
        var longName = "VeryLongModuleNameThatExceedsReasonableLimitsForModuleNaming";
        try {
            mockProcessModuleAnnotationWithValidation(longName, []);
            Assert.fail("Very long module name should be rejected");
        } catch (e: String) {
            Assert.isTrue(e.indexOf("too long") >= 0);
        }
    }
    
    /**
     * Test: Module name with special characters
     */
    public function testModuleNameWithSpecialChars() {
        try {
            mockProcessModuleAnnotationWithValidation("User@Service", []);
            Assert.fail("Module name with @ should be rejected");
        } catch (e: String) {
            Assert.isTrue(e.indexOf("invalid characters") >= 0);
        }
    }
    
    /**
     * Test: Pipe expression with unbalanced parentheses
     */
    public function testUnbalancedParentheses() {
        var isValid = mockIsValidPipeExpression("data |> func(missing |> format()");
        Assert.isFalse(isValid);
    }
    
    /**
     * Test: Empty pipe expression
     */
    public function testEmptyPipeExpression() {
        var isValid = mockIsValidPipeExpression("");
        Assert.isFalse(isValid);
    }
    
    /**
     * Test: Pipe expression with only pipe operators
     */
    public function testPipeExpressionOnlyOperators() {
        var isValid = mockIsValidPipeExpression("|> |> |>");
        Assert.isFalse(isValid);
    }
    
    /**
     * Test: Complex nested function calls in pipe
     */
    public function testComplexNestedPipe() {
        var expr = "data |> map(fn x -> transform(x, opts) end) |> filter(&valid?/1) |> reduce(0, &+/2)";
        var isValid = mockIsValidPipeExpression(expr);
        Assert.isTrue(isValid);
    }
    
    // === RUNTIME MOCKS ===
    // These simulate what ModuleMacro would generate with validation at compile-time
    
    function mockProcessModuleAnnotationWithValidation(name: String, imports: Array<String>): String {
        // Module name validation
        if (name == null || name == "") {
            throw "Module name cannot be empty";
        }
        
        if (name.charAt(0) != name.charAt(0).toUpperCase()) {
            throw "Module name must start with uppercase letter";
        }
        
        if (name.length > 50) {
            throw "Module name too long (max 50 characters)";
        }
        
        if (name.indexOf("@") >= 0 || name.indexOf("#") >= 0 || name.indexOf("$") >= 0) {
            throw "Module name contains invalid characters";
        }
        
        var reservedWords = ["And", "Or", "Not", "Do", "End", "If", "Else"];
        if (reservedWords.indexOf(name) >= 0) {
            throw 'Module name "$name" is a reserved keyword';
        }
        
        // Generate module
        var parts = ['defmodule $name do'];
        if (imports != null) {
            for (imp in imports) {
                parts.push('  alias Elixir.$imp');
            }
        }
        parts.push("end");
        return parts.join("\n");
    }
    
    function mockIsValidPipeExpression(expr: String): Bool {
        if (expr == null || expr == "") {
            return false;
        }
        
        // Check for empty pipes (|> |>)
        if (expr.indexOf("|> |>") >= 0) {
            return false;
        }
        
        // Check for starting/ending with pipe
        if (expr.indexOf("|>") == 0 || expr.lastIndexOf("|>") == expr.length - 2) {
            return false;
        }
        
        // Check balanced parentheses
        var parenCount = 0;
        for (i in 0...expr.length) {
            var char = expr.charAt(i);
            if (char == "(") parenCount++;
            else if (char == ")") parenCount--;
            if (parenCount < 0) return false;
        }
        if (parenCount != 0) return false;
        
        // Check if expression has any content besides pipes
        var withoutPipes = StringTools.trim(expr.split("|>").join(" "));
        if (withoutPipes == "") {
            return false;
        }
        
        return true;
    }
}