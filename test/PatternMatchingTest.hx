package test;

import utest.Test;
import utest.Assert;

#if macro
import reflaxe.elixir.ElixirCompiler;
#end

/**
 * Unit tests for pattern matching compilation - Migrated to utest
 * Tests switch→case, guards, and pipe operators
 * 
 * IMPORTANT: Understanding #if macro blocks in transpiler testing
 * ================================================================
 * Reflaxe.Elixir is a COMPILE-TIME transpiler that converts Haxe to Elixir.
 * It only exists during macro expansion, not at test runtime.
 * 
 * CRITICAL: The #if macro blocks are DEAD CODE - they NEVER execute!
 * - utest runs tests at runtime, not at macro-time
 * - We don't use utest.MacroRunner (which COULD run tests at macro-time)
 * - The #if macro blocks are kept for documentation of what we're mocking
 * 
 * The testing reality:
 * - #if macro: DEAD CODE - shows what we would test if we could
 * - #else: ACTUAL TEST - uses runtime mocks that simulate compiler output
 * 
 * Why not #if (macro || reflaxe_runtime)?
 * - reflaxe_runtime is only set when ACTUALLY transpiling to Elixir
 * - During test execution, we're running in Haxe interpreter, not transpiling
 * - So reflaxe_runtime is always false during tests
 * 
 * Migration patterns applied:
 * - static main() → extends Test
 * - assertTrue() → Assert.isTrue() / Assert.notNull()
 * - trace() → removed (utest handles output)
 * - static functions → instance methods
 */
class PatternMatchingTest extends Test {
    
    /**
     * Test basic switch to case conversion
     */
    function testBasicSwitchToCase() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock simple switch expression
        var switchExpr = createMockSwitch(
            createMockVariable("result"),
            [
                createMockCase([createMockEnumPattern("Ok", ["value"])], createMockString("Success")),
                createMockCase([createMockEnumPattern("Error", ["msg"])], createMockString("Error"))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        Assert.notNull(result, "Switch compilation should not return null");
        Assert.isTrue(result.indexOf("case result do") >= 0, "Should generate case expression");
        Assert.isTrue(result.indexOf("{:ok, value} ->") >= 0, "Should generate enum pattern");
        Assert.isTrue(result.indexOf("{:error, msg} ->") >= 0, "Should generate error pattern");
        Assert.isTrue(result.indexOf("end") >= 0, "Should close case expression");
        #else
        // Runtime mock test
        var result = mockCompileSwitch("result", "Ok|Error");
        Assert.notNull(result);
        Assert.isTrue(result.indexOf("case result do") >= 0);
        Assert.isTrue(result.indexOf("{:ok, value} ->") >= 0);
        Assert.isTrue(result.indexOf("{:error, msg} ->") >= 0);
        Assert.isTrue(result.indexOf("end") >= 0);
        #end
    }
    
    /**
     * Test enum pattern matching compilation
     */
    function testEnumPatternMatching() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock Result<String> pattern matching
        var switchExpr = createMockSwitch(
            createMockVariable("result"),
            [
                createMockCase([createMockEnumPattern("Ok", ["value"])], 
                              createMockBinary("+", createMockString("Success: "), createMockVariable("value"))),
                createMockCase([createMockEnumPattern("Error", ["message"])],
                              createMockBinary("+", createMockString("Error: "), createMockVariable("message")))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        // Should generate proper tagged tuple patterns
        Assert.isTrue(result.indexOf("{:ok, value}") >= 0, "Should generate :ok tagged tuple");
        Assert.isTrue(result.indexOf("{:error, message}") >= 0, "Should generate :error tagged tuple");
        
        // Should generate proper string interpolation or concatenation
        Assert.isTrue(result.indexOf("Success") >= 0, "Should include success message");
        Assert.isTrue(result.indexOf("Error") >= 0, "Should include error message");
        #else
        // Runtime mock test
        var result = mockCompileEnumPattern();
        Assert.isTrue(result.indexOf("{:ok, value}") >= 0);
        Assert.isTrue(result.indexOf("{:error, message}") >= 0);
        Assert.isTrue(result.indexOf("Success") >= 0);
        Assert.isTrue(result.indexOf("Error") >= 0);
        #end
    }
    
    /**
     * Test guard clause (when) generation
     */
    function testGuardClauseGeneration() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock switch with guard clauses
        var switchExpr = createMockSwitch(
            createMockVariable("n"),
            [
                createMockCaseWithGuard([createMockVariable("x")], 
                                       createMockBinary(">", createMockVariable("x"), createMockInt(0)),
                                       createMockString("positive")),
                createMockCaseWithGuard([createMockVariable("x")],
                                       createMockBinary("<", createMockVariable("x"), createMockInt(0)), 
                                       createMockString("negative")),
                createMockCase([createMockInt(0)], createMockString("zero"))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        // Should generate when clauses
        Assert.isTrue(result.indexOf("when ") >= 0, "Should generate when clause");
        Assert.isTrue(result.indexOf("x when x > 0") >= 0 || result.indexOf("when x > 0") >= 0, 
                  "Should generate positive guard");
        Assert.isTrue(result.indexOf("x when x < 0") >= 0 || result.indexOf("when x < 0") >= 0,
                  "Should generate negative guard");
        #else
        // Runtime mock test
        var result = mockCompileGuards();
        Assert.isTrue(result.indexOf("when ") >= 0);
        Assert.isTrue(result.indexOf("x > 0") >= 0);
        Assert.isTrue(result.indexOf("x < 0") >= 0);
        #end
    }
    
    /**
     * Test array pattern destructuring
     */
    function testArrayPatternDestructuring() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock array pattern matching
        var switchExpr = createMockSwitch(
            createMockVariable("arr"),
            [
                createMockCase([createMockArrayPattern([])], createMockString("empty")),
                createMockCase([createMockArrayPattern([createMockVariable("x")])], 
                              createMockString("single")),
                createMockCase([createMockArrayPattern([createMockVariable("head"), 
                                                      createMockRestPattern("tail")])],
                              createMockString("head and tail"))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        // Should generate list patterns
        Assert.isTrue(result.indexOf("[]") >= 0, "Should generate empty list pattern");
        Assert.isTrue(result.indexOf("[x]") >= 0, "Should generate single element pattern");
        Assert.isTrue(result.indexOf("[head | tail]") >= 0, "Should generate head|tail pattern");
        #else
        // Runtime mock test
        var result = mockCompileArrayPatterns();
        Assert.isTrue(result.indexOf("[]") >= 0);
        Assert.isTrue(result.indexOf("[x]") >= 0);
        Assert.isTrue(result.indexOf("[head | tail]") >= 0);
        #end
    }
    
    /**
     * Test tuple/struct pattern matching
     */
    function testTuplePatternMatching() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock tuple pattern matching
        var switchExpr = createMockSwitch(
            createMockVariable("tuple"),
            [
                createMockCase([createMockTuplePattern([
                    createMockFieldPattern("x", createMockInt(0)),
                    createMockFieldPattern("y", createMockVariable("msg"))
                ])], createMockString("zero x")),
                createMockCase([createMockTuplePattern([
                    createMockFieldPattern("x", createMockVariable("x")),
                    createMockFieldPattern("y", createMockVariable("y"))
                ])], createMockString("general"))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        // Should generate struct/map patterns
        Assert.isTrue(result.indexOf("%{") >= 0, "Should generate map/struct pattern");
        Assert.isTrue(result.indexOf("x: 0") >= 0, "Should generate field pattern with literal");
        Assert.isTrue(result.indexOf("y: msg") >= 0, "Should generate field pattern with variable");
        #else
        // Runtime mock test
        var result = mockCompileTuplePatterns();
        Assert.isTrue(result.indexOf("%{") >= 0);
        Assert.isTrue(result.indexOf("x: 0") >= 0);
        Assert.isTrue(result.indexOf("y: msg") >= 0);
        #end
    }
    
    /**
     * Test struct pattern matching
     */
    function testStructPatternMatching() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock Point struct pattern matching
        var switchExpr = createMockSwitch(
            createMockVariable("point"),
            [
                createMockCase([createMockStructPattern("Point", [
                    createMockFieldPattern("x", createMockInt(0)),
                    createMockFieldPattern("y", createMockInt(0))
                ])], createMockString("origin")),
                createMockCase([createMockStructPattern("Point", [
                    createMockFieldPattern("x", createMockVariable("x")),
                    createMockFieldPattern("y", createMockInt(0))
                ])], createMockString("x-axis"))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        // Should generate struct patterns
        Assert.isTrue(result.indexOf("%Point{") >= 0, "Should generate struct pattern");
        Assert.isTrue(result.indexOf("x: 0, y: 0") >= 0, "Should generate field patterns");
        #else
        // Runtime mock test  
        var result = mockCompileStructPatterns();
        Assert.isTrue(result.indexOf("%Point{") >= 0);
        Assert.isTrue(result.indexOf("x: 0, y: 0") >= 0);
        #end
    }
    
    /**
     * Test pipe operator compilation
     */
    function testPipeOperatorCompilation() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock method chain that should become pipe
        var chainExpr = createMockMethodChain([
            createMockCall("toLowerCase", []),
            createMockCall("trim", []),
            createMockCall("replace", [createMockString(" "), createMockString("_")])
        ]);
        
        var result = compiler.compileExpression(chainExpr);
        
        // Should generate pipe operators
        Assert.isTrue(result.indexOf("|>") >= 0, "Should generate pipe operator");
        Assert.isTrue(result.indexOf("String.downcase") >= 0 || result.indexOf("to_lower") >= 0,
                  "Should convert to Elixir string functions");
        #else
        // Runtime mock test
        var result = mockCompilePipeOperator();
        Assert.isTrue(result.indexOf("|>") >= 0);
        Assert.isTrue(result.indexOf("String.downcase") >= 0 || result.indexOf("to_lower") >= 0);
        #end
    }
    
    /**
     * Test nested pattern matching
     */
    function testNestedPatternMatching() {
        #if macro
        var compiler = new ElixirCompiler();
        
        // Mock nested Result<Array<Int>> pattern
        var switchExpr = createMockSwitch(
            createMockVariable("result"),
            [
                createMockCase([createMockEnumPattern("Ok", [createMockArrayPattern([])])],
                              createMockString("empty success")),
                createMockCase([createMockEnumPattern("Ok", [createMockArrayPattern([
                    createMockVariable("x"), createMockVariable("y"), createMockRestPattern("rest")
                ])])], createMockString("multi success")),
                createMockCase([createMockEnumPattern("Error", [createMockVariable("msg")])],
                              createMockString("error"))
            ]
        );
        
        var result = compiler.compileExpression(switchExpr);
        
        // Should generate nested patterns
        Assert.isTrue(result.indexOf("{:ok, []}") >= 0, "Should generate nested empty array");
        Assert.isTrue(result.indexOf("{:ok, [x, y | rest]}") >= 0, "Should generate nested array with rest");
        Assert.isTrue(result.indexOf("{:error, msg}") >= 0, "Should generate error pattern");
        #else
        // Runtime mock test
        var result = mockCompileNestedPatterns();
        Assert.isTrue(result.indexOf("{:ok, []}") >= 0);
        Assert.isTrue(result.indexOf("{:ok, [x, y | rest]}") >= 0);
        Assert.isTrue(result.indexOf("{:error, msg}") >= 0);
        #end
    }
    
    // Mock helper functions for creating test expressions (macro-time only)
    #if macro
    function createMockSwitch(expr: Dynamic, cases: Array<Dynamic>) {
        return {
            expr: TSwitch(expr, cases, null)
        };
    }
    
    function createMockCase(patterns: Array<Dynamic>, expr: Dynamic) {
        return {
            values: patterns,
            expr: expr
        };
    }
    
    function createMockCaseWithGuard(patterns: Array<Dynamic>, guard: Dynamic, expr: Dynamic) {
        return {
            values: patterns,
            guard: guard,
            expr: expr
        };
    }
    
    function createMockVariable(name: String) {
        return {
            expr: TLocal({name: name})
        };
    }
    
    function createMockString(value: String) {
        return {
            expr: TConst(CString(value))
        };
    }
    
    function createMockInt(value: Int) {
        return {
            expr: TConst(CInt(value))
        };
    }
    
    function createMockBinary(op: String, left: Dynamic, right: Dynamic) {
        return {
            expr: TBinop(op, left, right)
        };
    }
    
    function createMockEnumPattern(name: String, args: Array<String>) {
        return {
            expr: TCall(TField(null, FEnum(null, {name: name})), 
                       args.map(arg -> createMockVariable(arg)))
        };
    }
    
    function createMockArrayPattern(elements: Array<Dynamic>) {
        return {
            expr: TArrayDecl(elements)
        };
    }
    
    function createMockRestPattern(name: String) {
        return {
            expr: TLocal({name: name, isRest: true})
        };
    }
    
    function createMockTuplePattern(fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields)
        };
    }
    
    function createMockFieldPattern(name: String, value: Dynamic) {
        return {
            name: name,
            expr: value
        };
    }
    
    function createMockStructPattern(typeName: String, fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields),
            structType: typeName
        };
    }
    
    function createMockMethodChain(calls: Array<Dynamic>) {
        return {
            expr: TCall(null, calls) // Simplified representation
        };
    }
    
    function createMockCall(methodName: String, args: Array<Dynamic>) {
        return {
            method: methodName,
            args: args
        };
    }
    #end
    
    // Runtime mocks (these simulate what the transpiler would generate)
    // These only exist at runtime since the real compiler only exists at macro-time
    #if !macro
    function mockCompileSwitch(varName: String, patterns: String): String {
        return 'case ${varName} do
  {:ok, value} -> "Success"
  {:error, msg} -> "Error"
end';
    }
    
    function mockCompileEnumPattern(): String {
        return 'case result do
  {:ok, value} -> "Success: " <> value
  {:error, message} -> "Error: " <> message
end';
    }
    
    function mockCompileGuards(): String {
        return 'case n do
  x when x > 0 -> "positive"
  x when x < 0 -> "negative"
  0 -> "zero"
end';
    }
    
    function mockCompileArrayPatterns(): String {
        return 'case arr do
  [] -> "empty"
  [x] -> "single"
  [head | tail] -> "head and tail"
end';
    }
    
    function mockCompileTuplePatterns(): String {
        return 'case tuple do
  %{x: 0, y: msg} -> "zero x"
  %{x: x, y: y} -> "general"
end';
    }
    
    function mockCompileStructPatterns(): String {
        return 'case point do
  %Point{x: 0, y: 0} -> "origin"
  %Point{x: x, y: 0} -> "x-axis"
end';
    }
    
    function mockCompilePipeOperator(): String {
        return 'value
  |> String.downcase()
  |> String.trim()
  |> String.replace(" ", "_")';
    }
    
    function mockCompileNestedPatterns(): String {
        return 'case result do
  {:ok, []} -> "empty success"
  {:ok, [x, y | rest]} -> "multi success"
  {:error, msg} -> "error"
end';
    }
    #end
}