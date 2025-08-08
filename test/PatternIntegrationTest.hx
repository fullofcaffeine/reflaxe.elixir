package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;

/**
 * Integration tests for pattern matching system
 * Testing Trophy focused - verifies complete pattern matching compilation
 */
class PatternIntegrationTest {
    public static function main() {
        trace("Running Pattern Matching Integration Tests...");
        
        testCompletePatternMatchingSystem();
        testPhoenixStylePatternMatching();
        testEctoQueryPatternMatching();
        testLiveViewEventPatterns();
        testPipeOperatorChains();
        testComplexGuardCombinations();
        testRealWorldPatterns();
        
        trace("✅ All Pattern Matching Integration tests passed!");
    }
    
    /**
     * Test complete pattern matching system with all features
     */
    static function testCompletePatternMatchingSystem() {
        trace("TEST: Complete pattern matching system");
        
        var compiler = new ElixirCompiler();
        
        // Mock comprehensive pattern matching function
        var funcData = createMockFunction("handleMessage", 
            createMockSwitch(createMockVariable("message"), [
                // Simple enum pattern
                createMockCase([createMockEnumPattern("Info", ["text"])],
                              createMockString("Info received")),
                
                // Pattern with guard
                createMockCaseWithGuard([createMockEnumPattern("Warning", ["text", "level"])],
                                       createMockBinary(">", createMockVariable("level"), createMockInt(5)),
                                       createMockString("High warning")),
                
                // Struct pattern matching
                createMockCase([createMockStructPattern("User", [
                    createMockFieldPattern("active", createMockBool(true)),
                    createMockFieldPattern("role", createMockString("admin"))
                ])], createMockString("Active admin")),
                
                // Array destructuring
                createMockCase([createMockArrayPattern([
                    createMockVariable("head"),
                    createMockRestPattern("tail")
                ])], createMockString("List with head and tail")),
                
                // Wildcard
                createMockCase([createMockWildcard()], createMockString("Unknown"))
            ])
        );
        
        var result = compiler.compileExpression(funcData);
        
        // Verify complete case structure
        assertTrue(result.indexOf("case message do") >= 0, "Should generate case expression");
        
        // Verify enum patterns
        assertTrue(result.indexOf("{:info, text}") >= 0, "Should generate enum pattern");
        assertTrue(result.indexOf("{:warning, text, level}") >= 0, "Should generate multi-arg enum");
        
        // Verify guard clauses
        assertTrue(result.indexOf("when ") >= 0, "Should generate guard clause");
        assertTrue(result.indexOf("level > 5") >= 0, "Should generate guard condition");
        
        // Verify struct patterns
        assertTrue(result.indexOf("%User{") >= 0, "Should generate struct pattern");
        assertTrue(result.indexOf("active: true") >= 0, "Should generate field patterns");
        
        // Verify list patterns
        assertTrue(result.indexOf("[head | tail]") >= 0, "Should generate list destructuring");
        
        // Verify wildcard
        assertTrue(result.indexOf("_ ->") >= 0, "Should generate wildcard pattern");
        
        trace("✅ Complete pattern matching system test passed");
    }
    
    /**
     * Test Phoenix-style pattern matching
     */
    static function testPhoenixStylePatternMatching() {
        trace("TEST: Phoenix-style pattern matching");
        
        var compiler = new ElixirCompiler();
        
        // Mock Phoenix controller action with pattern matching
        var funcData = createMockFunction("show",
            createMockSwitch(createMockVariable("params"), [
                // Success case with ID extraction
                createMockCase([createMockMapPattern([
                    createMockFieldPattern("id", createMockVariable("id"))
                ])], createMockCall("findUser", [createMockVariable("id")])),
                
                // Missing ID case
                createMockCase([createMockMapPattern([])],
                              createMockTuple([createMockAtom("error"), createMockString("missing_id")]))
            ])
        );
        
        var result = compiler.compileExpression(funcData);
        
        // Should generate Phoenix-style patterns
        assertTrue(result.indexOf("%{\"id\" => id}") >= 0 || result.indexOf("%{id: id}") >= 0,
                  "Should generate map pattern for params");
        assertTrue(result.indexOf("find_user(id)") >= 0, "Should call function with extracted param");
        assertTrue(result.indexOf("{:error, \"missing_id\"}") >= 0, "Should generate error tuple");
        
        trace("✅ Phoenix-style pattern matching test passed");
    }
    
    /**
     * Test Ecto query pattern matching
     */
    static function testEctoQueryPatternMatching() {
        trace("TEST: Ecto query pattern matching");
        
        var compiler = new ElixirCompiler();
        
        // Mock Ecto query result handling
        var funcData = createMockFunction("handleQueryResult",
            createMockSwitch(createMockVariable("result"), [
                // Single user found
                createMockCase([createMockTuple([createMockAtom("ok"), createMockVariable("user")])],
                              createMockCall("renderUser", [createMockVariable("user")])),
                
                // Multiple users found
                createMockCase([createMockTuple([createMockAtom("ok"), createMockArrayPattern([
                    createMockVariable("first"),
                    createMockRestPattern("others")
                ])])], createMockCall("renderUsers", [createMockVariable("first"), createMockVariable("others")])),
                
                // No results
                createMockCase([createMockTuple([createMockAtom("error"), createMockAtom("not_found")])],
                              createMockCall("renderNotFound", [])),
                
                // Database error
                createMockCase([createMockTuple([createMockAtom("error"), createMockVariable("reason")])],
                              createMockCall("renderError", [createMockVariable("reason")]))
            ])
        );
        
        var result = compiler.compileExpression(funcData);
        
        // Should generate Ecto-style patterns
        assertTrue(result.indexOf("{:ok, user}") >= 0, "Should generate success tuple");
        assertTrue(result.indexOf("{:ok, [first | others]}") >= 0, "Should generate list destructuring");
        assertTrue(result.indexOf("{:error, :not_found}") >= 0, "Should generate not found pattern");
        assertTrue(result.indexOf("{:error, reason}") >= 0, "Should generate error pattern");
        
        trace("✅ Ecto query pattern matching test passed");
    }
    
    /**
     * Test LiveView event patterns
     */
    static function testLiveViewEventPatterns() {
        trace("TEST: LiveView event patterns");
        
        var compiler = new ElixirCompiler();
        
        // Mock LiveView handle_event with pattern matching
        var funcData = createMockFunction("handleEvent",
            createMockSwitch(createMockTuple([createMockVariable("event"), createMockVariable("params")]), [
                // Click event with element ID
                createMockCase([createMockTuple([createMockString("click"), createMockMapPattern([
                    createMockFieldPattern("element_id", createMockVariable("id"))
                ])])], createMockCall("handleClick", [createMockVariable("id")])),
                
                // Form submit with form data
                createMockCase([createMockTuple([createMockString("submit"), createMockMapPattern([
                    createMockFieldPattern("form", createMockVariable("form_data"))
                ])])], createMockCall("handleSubmit", [createMockVariable("form_data")])),
                
                // Key press with key code
                createMockCaseWithGuard([createMockTuple([createMockString("keypress"), createMockMapPattern([
                    createMockFieldPattern("key", createMockVariable("key"))
                ])])], createMockBinary("==", createMockVariable("key"), createMockString("Enter")),
                                       createMockCall("handleEnter", [])),
                
                // Unknown event
                createMockCase([createMockTuple([createMockVariable("unknown"), createMockWildcard()])],
                              createMockCall("logUnknownEvent", [createMockVariable("unknown")]))
            ])
        );
        
        var result = compiler.compileExpression(funcData);
        
        // Should generate LiveView patterns
        assertTrue(result.indexOf("{\"click\", %{\"element_id\" => id}}") >= 0,
                  "Should generate click event pattern");
        assertTrue(result.indexOf("{\"submit\", %{\"form\" => form_data}}") >= 0,
                  "Should generate submit event pattern");
        assertTrue(result.indexOf("when key == \"Enter\"") >= 0,
                  "Should generate key guard");
        
        trace("✅ LiveView event patterns test passed");
    }
    
    /**
     * Test pipe operator chains
     */
    static function testPipeOperatorChains() {
        trace("TEST: Pipe operator chains");
        
        var compiler = new ElixirCompiler();
        
        // Mock complex pipe chain
        var pipeExpr = createMockPipeChain(createMockVariable("data"), [
            createMockCall("filterValid", []),
            createMockCall("mapToString", []),
            createMockCall("sortBy", [createMockLambda("length")]),
            createMockCall("take", [createMockInt(10)]),
            createMockCall("enumerate", [])
        ]);
        
        var result = compiler.compileExpression(pipeExpr);
        
        // Should generate pipe chain
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operators");
        assertTrue(result.indexOf("filter_valid()") >= 0, "Should convert function names");
        assertTrue(result.indexOf("map_to_string()") >= 0, "Should convert camelCase to snake_case");
        assertTrue(result.indexOf("sort_by(&String.length/1)") >= 0 || 
                  result.indexOf("sort_by(fn x -> String.length(x) end)") >= 0,
                  "Should convert lambda expressions");
        
        trace("✅ Pipe operator chains test passed");
    }
    
    /**
     * Test complex guard combinations
     */
    static function testComplexGuardCombinations() {
        trace("TEST: Complex guard combinations");
        
        var compiler = new ElixirCompiler();
        
        // Mock complex guards
        var funcData = createMockFunction("validateInput",
            createMockSwitch(createMockVariable("input"), [
                // Multiple conditions with AND
                createMockCaseWithGuard([createMockStructPattern("Input", [
                    createMockFieldPattern("value", createMockVariable("v")),
                    createMockFieldPattern("type", createMockVariable("t"))
                ])], createMockAnd([
                    createMockBinary(">", createMockVariable("v"), createMockInt(0)),
                    createMockBinary("==", createMockVariable("t"), createMockString("number"))
                ]), createMockString("valid number")),
                
                // Multiple conditions with OR
                createMockCaseWithGuard([createMockVariable("x")],
                                       createMockOr([
                                           createMockBinary("==", createMockVariable("x"), createMockString("admin")),
                                           createMockBinary("==", createMockVariable("x"), createMockString("super"))
                                       ]), createMockString("privileged user")),
                
                // Function call in guard
                createMockCaseWithGuard([createMockVariable("text")],
                                       createMockCall("isValidEmail", [createMockVariable("text")]),
                                       createMockString("valid email"))
            ])
        );
        
        var result = compiler.compileExpression(funcData);
        
        // Should generate complex guards
        assertTrue(result.indexOf("when v > 0 and t == \"number\"") >= 0,
                  "Should generate AND guard");
        assertTrue(result.indexOf("when x == \"admin\" or x == \"super\"") >= 0,
                  "Should generate OR guard");
        assertTrue(result.indexOf("when is_valid_email(text)") >= 0,
                  "Should generate function call guard");
        
        trace("✅ Complex guard combinations test passed");
    }
    
    /**
     * Test real-world Phoenix patterns
     */
    static function testRealWorldPatterns() {
        trace("TEST: Real-world Phoenix patterns");
        
        var compiler = new ElixirCompiler();
        
        // Mock real Phoenix controller action
        var funcData = createMockFunction("update",
            createMockSwitch(createMockCall("updateUser", [createMockVariable("user"), createMockVariable("params")]), [
                // Successful update
                createMockCase([createMockTuple([createMockAtom("ok"), createMockVariable("updated_user")])],
                              createMockCall("render", [createMockString("show.json"), 
                                                       createMockMapLiteral([
                                                           createMockField("user", createMockVariable("updated_user"))
                                                       ])])),
                
                // Validation errors
                createMockCase([createMockTuple([createMockAtom("error"), createMockVariable("changeset")])],
                              createMockCall("render", [createMockString("errors.json"),
                                                       createMockMapLiteral([
                                                           createMockField("errors", 
                                                                         createMockCall("translateErrors", [createMockVariable("changeset")]))
                                                       ])])),
                
                // Not found
                createMockCase([createMockAtom("nil")],
                              createMockCall("sendResp", [createMockInt(404), createMockString("Not found")]))
            ])
        );
        
        var result = compiler.compileExpression(funcData);
        
        // Should generate Phoenix controller patterns
        assertTrue(result.indexOf("{:ok, updated_user}") >= 0, "Should generate success tuple");
        assertTrue(result.indexOf("{:error, changeset}") >= 0, "Should generate error tuple");
        assertTrue(result.indexOf("render(") >= 0, "Should call render function");
        assertTrue(result.indexOf("%{user: updated_user}") >= 0, "Should generate response map");
        
        trace("✅ Real-world Phoenix patterns test passed");
    }
    
    // Mock helper functions (extensive set for complex patterns)
    static function createMockFunction(name: String, body: Dynamic) {
        return {
            name: name,
            body: body
        };
    }
    
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
    
    static function createMockBool(value: Bool) {
        return {
            expr: TConst(CBool(value))
        };
    }
    
    static function createMockAtom(name: String) {
        return {
            expr: TConst(CAtom(name))
        };
    }
    
    static function createMockBinary(op: String, left: Dynamic, right: Dynamic) {
        return {
            expr: TBinop(op, left, right)
        };
    }
    
    static function createMockAnd(conditions: Array<Dynamic>) {
        return {
            expr: TBinop("&&", conditions[0], conditions[1])
        };
    }
    
    static function createMockOr(conditions: Array<Dynamic>) {
        return {
            expr: TBinop("||", conditions[0], conditions[1])
        };
    }
    
    static function createMockCall(name: String, args: Array<Dynamic>) {
        return {
            expr: TCall(TField(null, name), args)
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
    
    static function createMockMapPattern(fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields)
        };
    }
    
    static function createMockStructPattern(typeName: String, fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields),
            structType: typeName
        };
    }
    
    static function createMockFieldPattern(name: String, value: Dynamic) {
        return {
            name: name,
            expr: value
        };
    }
    
    static function createMockTuple(elements: Array<Dynamic>) {
        return {
            expr: TTuple(elements)
        };
    }
    
    static function createMockWildcard() {
        return {
            expr: TWildcard()
        };
    }
    
    static function createMockPipeChain(initial: Dynamic, calls: Array<Dynamic>) {
        return {
            expr: TPipe(initial, calls)
        };
    }
    
    static function createMockLambda(body: String) {
        return {
            expr: TLambda(body)
        };
    }
    
    static function createMockMapLiteral(fields: Array<Dynamic>) {
        return {
            expr: TObjectDecl(fields)
        };
    }
    
    static function createMockField(name: String, value: Dynamic) {
        return {
            name: name,
            expr: value
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