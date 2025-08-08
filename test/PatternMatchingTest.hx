package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;

/**
 * Unit tests for pattern matching compilation
 * Tests switch→case, guards, and pipe operators
 */
class PatternMatchingTest {
    public static function main() {
        trace("Running Pattern Matching Tests...");
        
        testBasicSwitchToCase();
        testEnumPatternMatching();
        testGuardClauseGeneration();
        testArrayPatternDestructuring();
        testTuplePatternMatching();
        testStructPatternMatching();
        testPipeOperatorCompilation();
        testNestedPatternMatching();
        
        trace("✅ All Pattern Matching tests passed!");
    }
    
    /**
     * Test basic switch to case conversion
     */
    static function testBasicSwitchToCase() {
        trace("TEST: Basic switch to case conversion");
        
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
        
        assertTrue(result != null, "Switch compilation should not return null");
        assertTrue(result.indexOf("case result do") >= 0, "Should generate case expression");
        assertTrue(result.indexOf("{:ok, value} ->") >= 0, "Should generate enum pattern");
        assertTrue(result.indexOf("{:error, msg} ->") >= 0, "Should generate error pattern");
        assertTrue(result.indexOf("end") >= 0, "Should close case expression");
        
        trace("✅ Basic switch to case conversion test passed");
    }
    
    /**
     * Test enum pattern matching compilation
     */
    static function testEnumPatternMatching() {
        trace("TEST: Enum pattern matching compilation");
        
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
        assertTrue(result.indexOf("{:ok, value}") >= 0, "Should generate :ok tagged tuple");
        assertTrue(result.indexOf("{:error, message}") >= 0, "Should generate :error tagged tuple");
        
        // Should generate proper string interpolation or concatenation
        assertTrue(result.indexOf("Success") >= 0, "Should include success message");
        assertTrue(result.indexOf("Error") >= 0, "Should include error message");
        
        trace("✅ Enum pattern matching compilation test passed");
    }
    
    /**
     * Test guard clause (when) generation
     */
    static function testGuardClauseGeneration() {
        trace("TEST: Guard clause generation");
        
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
        assertTrue(result.indexOf("when ") >= 0, "Should generate when clause");
        assertTrue(result.indexOf("x when x > 0") >= 0 || result.indexOf("when x > 0") >= 0, 
                  "Should generate positive guard");
        assertTrue(result.indexOf("x when x < 0") >= 0 || result.indexOf("when x < 0") >= 0,
                  "Should generate negative guard");
        
        trace("✅ Guard clause generation test passed");
    }
    
    /**
     * Test array pattern destructuring
     */
    static function testArrayPatternDestructuring() {
        trace("TEST: Array pattern destructuring");
        
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
        assertTrue(result.indexOf("[]") >= 0, "Should generate empty list pattern");
        assertTrue(result.indexOf("[x]") >= 0, "Should generate single element pattern");
        assertTrue(result.indexOf("[head | tail]") >= 0, "Should generate head|tail pattern");
        
        trace("✅ Array pattern destructuring test passed");
    }
    
    /**
     * Test tuple/struct pattern matching
     */
    static function testTuplePatternMatching() {
        trace("TEST: Tuple pattern matching");
        
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
        assertTrue(result.indexOf("%{") >= 0, "Should generate map/struct pattern");
        assertTrue(result.indexOf("x: 0") >= 0, "Should generate field pattern with literal");
        assertTrue(result.indexOf("y: msg") >= 0, "Should generate field pattern with variable");
        
        trace("✅ Tuple pattern matching test passed");
    }
    
    /**
     * Test struct pattern matching
     */
    static function testStructPatternMatching() {
        trace("TEST: Struct pattern matching");
        
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
        assertTrue(result.indexOf("%Point{") >= 0, "Should generate struct pattern");
        assertTrue(result.indexOf("x: 0, y: 0") >= 0, "Should generate field patterns");
        
        trace("✅ Struct pattern matching test passed");
    }
    
    /**
     * Test pipe operator compilation
     */
    static function testPipeOperatorCompilation() {
        trace("TEST: Pipe operator compilation");
        
        var compiler = new ElixirCompiler();
        
        // Mock method chain that should become pipe
        var chainExpr = createMockMethodChain([
            createMockCall("toLowerCase", []),
            createMockCall("trim", []),
            createMockCall("replace", [createMockString(" "), createMockString("_")])
        ]);
        
        var result = compiler.compileExpression(chainExpr);
        
        // Should generate pipe operators
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operator");
        assertTrue(result.indexOf("String.downcase") >= 0 || result.indexOf("to_lower") >= 0,
                  "Should convert to Elixir string functions");
        
        trace("✅ Pipe operator compilation test passed");
    }
    
    /**
     * Test nested pattern matching
     */
    static function testNestedPatternMatching() {
        trace("TEST: Nested pattern matching");
        
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
        assertTrue(result.indexOf("{:ok, []}") >= 0, "Should generate nested empty array");
        assertTrue(result.indexOf("{:ok, [x, y | rest]}") >= 0, "Should generate nested array with rest");
        assertTrue(result.indexOf("{:error, msg}") >= 0, "Should generate error pattern");
        
        trace("✅ Nested pattern matching test passed");
    }
    
    // Mock helper functions for creating test expressions
    static function createMockSwitch(expr: Dynamic, cases: Array<Dynamic>) {
        return {
            expr: TSwitch(expr, cases, null)
        };
    }
    
    static function createMockCase(patterns: Array<Dynamic>, expr: Dynamic) {
        return {
            values: patterns,
            expr: expr
        };
    }
    
    static function createMockCaseWithGuard(patterns: Array<Dynamic>, guard: Dynamic, expr: Dynamic) {
        return {
            values: patterns,
            guard: guard,
            expr: expr
        };
    }
    
    static function createMockVariable(name: String) {
        return {
            expr: TLocal({name: name})
        };
    }
    
    static function createMockString(value: String) {
        return {
            expr: TConst(CString(value))
        };
    }
    
    static function createMockInt(value: Int) {
        return {
            expr: TConst(CInt(value))
        };
    }
    
    static function createMockBinary(op: String, left: Dynamic, right: Dynamic) {
        return {
            expr: TBinop(op, left, right)
        };
    }
    
    static function createMockEnumPattern(name: String, args: Array<String>) {
        return {
            expr: TCall(TField(null, FEnum(null, {name: name})), 
                       args.map(arg -> createMockVariable(arg)))
        };
    }
    
    static function createMockArrayPattern(elements: Array<Dynamic>) {
        return {
            expr: TArrayDecl(elements)
        };
    }
    
    static function createMockRestPattern(name: String) {
        return {
            expr: TLocal({name: name, isRest: true})
        };
    }
    
    static function createMockTuplePattern(fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields)
        };
    }
    
    static function createMockFieldPattern(name: String, value: Dynamic) {
        return {
            name: name,
            expr: value
        };
    }
    
    static function createMockStructPattern(typeName: String, fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields),
            structType: typeName
        };
    }
    
    static function createMockMethodChain(calls: Array<Dynamic>) {
        return {
            expr: TCall(null, calls) // Simplified representation
        };
    }
    
    static function createMockCall(methodName: String, args: Array<Dynamic>) {
        return {
            method: methodName,
            args: args
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
}

#end