package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirCompiler;

/**
 * Specific tests for pipe operator |> compilation
 * Tests method chaining conversion to Elixir pipes
 */
class PipeOperatorTest {
    public static function main() {
        trace("Running Pipe Operator Tests...");
        
        testBasicMethodChaining();
        testPipeWithArguments();
        testComplexPipeChain();
        testAnonymousFunctionPipes();
        testEnumPipes();
        testMapPipes();
        testPhoenixPipePatterns();
        
        trace("✅ All Pipe Operator tests passed!");
    }
    
    /**
     * Test basic method chaining to pipe conversion
     */
    static function testBasicMethodChaining() {
        trace("TEST: Basic method chaining to pipe");
        
        var compiler = new ElixirCompiler();
        
        // Mock: "hello".toLowerCase().trim()
        var chainExpr = createMockChain(
            createMockString("hello"),
            ["toLowerCase", "trim"]
        );
        
        var result = compiler.compileExpression(chainExpr);
        
        // Should generate pipe chain
        assertTrue(result != null, "Pipe compilation should not return null");
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operator");
        assertTrue(result.indexOf("\"hello\"") >= 0, "Should start with initial value");
        assertTrue(result.indexOf("String.downcase") >= 0 || result.indexOf("downcase") >= 0,
                  "Should convert to Elixir string function");
        assertTrue(result.indexOf("String.trim") >= 0 || result.indexOf("trim") >= 0,
                  "Should convert trim function");
        
        trace("✅ Basic method chaining to pipe test passed");
    }
    
    /**
     * Test pipe with function arguments
     */
    static function testPipeWithArguments() {
        trace("TEST: Pipe with function arguments");
        
        var compiler = new ElixirCompiler();
        
        // Mock: value.replace("old", "new").split(",")
        var chainExpr = createMockChainWithArgs(
            createMockVariable("value"),
            [
                {method: "replace", args: [createMockString("old"), createMockString("new")]},
                {method: "split", args: [createMockString(",")]}
            ]
        );
        
        var result = compiler.compileExpression(chainExpr);
        
        // Should generate pipe with arguments
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operator");
        assertTrue(result.indexOf("String.replace(\"old\", \"new\")") >= 0 ||
                  result.indexOf("replace(_, \"old\", \"new\")") >= 0,
                  "Should handle function arguments in pipe");
        assertTrue(result.indexOf("String.split(\",\")") >= 0 ||
                  result.indexOf("split(_, \",\")") >= 0,
                  "Should handle split arguments");
        
        trace("✅ Pipe with function arguments test passed");
    }
    
    /**
     * Test complex pipe chain with multiple operations
     */
    static function testComplexPipeChain() {
        trace("TEST: Complex pipe chain");
        
        var compiler = new ElixirCompiler();
        
        // Mock: data.filter(x -> x > 0).map(x -> x * 2).reduce((a, b) -> a + b, 0)
        var chainExpr = createMockComplexChain(
            createMockVariable("data"),
            [
                {method: "filter", args: [createMockLambda("x", createMockBinary(">", createMockVariable("x"), createMockInt(0)))]},
                {method: "map", args: [createMockLambda("x", createMockBinary("*", createMockVariable("x"), createMockInt(2)))]},
                {method: "reduce", args: [createMockLambda2("a", "b", createMockBinary("+", createMockVariable("a"), createMockVariable("b"))), createMockInt(0)]}
            ]
        );
        
        var result = compiler.compileExpression(chainExpr);
        
        // Should generate Enum pipe chain
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operators");
        assertTrue(result.indexOf("Enum.filter") >= 0, "Should use Enum.filter");
        assertTrue(result.indexOf("Enum.map") >= 0, "Should use Enum.map");
        assertTrue(result.indexOf("Enum.reduce") >= 0, "Should use Enum.reduce");
        
        // Should convert lambdas
        assertTrue(result.indexOf("fn x -> x > 0 end") >= 0 || result.indexOf("&(&1 > 0)") >= 0,
                  "Should convert filter lambda");
        
        trace("✅ Complex pipe chain test passed");
    }
    
    /**
     * Test anonymous function pipes
     */
    static function testAnonymousFunctionPipes() {
        trace("TEST: Anonymous function pipes");
        
        var compiler = new ElixirCompiler();
        
        // Mock: value |> (x -> x + 1) |> (x -> x * 2)
        var pipeExpr = createMockAnonymousPipe(
            createMockVariable("value"),
            [
                createMockLambda("x", createMockBinary("+", createMockVariable("x"), createMockInt(1))),
                createMockLambda("x", createMockBinary("*", createMockVariable("x"), createMockInt(2)))
            ]
        );
        
        var result = compiler.compileExpression(pipeExpr);
        
        // Should generate anonymous function pipes
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operators");
        assertTrue(result.indexOf("fn x -> x + 1 end") >= 0 || result.indexOf("(&(&1 + 1))") >= 0,
                  "Should generate anonymous function");
        
        trace("✅ Anonymous function pipes test passed");
    }
    
    /**
     * Test Enum-specific pipe patterns
     */
    static function testEnumPipes() {
        trace("TEST: Enum pipe patterns");
        
        var compiler = new ElixirCompiler();
        
        // Mock: list.map(transform).filter(predicate).sort().first()
        var enumChain = createMockEnumChain(
            createMockVariable("list"),
            ["map", "filter", "sort", "first"]
        );
        
        var result = compiler.compileExpression(enumChain);
        
        // Should use Enum module functions
        assertTrue(result.indexOf("Enum.map") >= 0, "Should use Enum.map");
        assertTrue(result.indexOf("Enum.filter") >= 0, "Should use Enum.filter");
        assertTrue(result.indexOf("Enum.sort") >= 0, "Should use Enum.sort");
        assertTrue(result.indexOf("List.first") >= 0 || result.indexOf("Enum.at(_, 0)") >= 0,
                  "Should handle first/head operation");
        
        trace("✅ Enum pipe patterns test passed");
    }
    
    /**
     * Test Map-specific pipe patterns
     */
    static function testMapPipes() {
        trace("TEST: Map pipe patterns");
        
        var compiler = new ElixirCompiler();
        
        // Mock: map.put("key", "value").get("other").getOrDefault("default")
        var mapChain = createMockMapChain(
            createMockVariable("map"),
            [
                {method: "put", args: [createMockString("key"), createMockString("value")]},
                {method: "get", args: [createMockString("other")]},
                {method: "getOrDefault", args: [createMockString("default")]}
            ]
        );
        
        var result = compiler.compileExpression(mapChain);
        
        // Should use Map module functions
        assertTrue(result.indexOf("Map.put") >= 0, "Should use Map.put");
        assertTrue(result.indexOf("Map.get") >= 0, "Should use Map.get");
        assertTrue(result.indexOf("Map.get(_, \"other\", \"default\")") >= 0 ||
                  result.indexOf("Map.get(_, \"other\") || \"default\"") >= 0,
                  "Should handle getOrDefault");
        
        trace("✅ Map pipe patterns test passed");
    }
    
    /**
     * Test Phoenix-specific pipe patterns
     */
    static function testPhoenixPipePatterns() {
        trace("TEST: Phoenix pipe patterns");
        
        var compiler = new ElixirCompiler();
        
        // Mock: conn.assignUser(user).putFlash("info", "Welcome").render("index.html")
        var phoenixChain = createMockPhoenixChain(
            createMockVariable("conn"),
            [
                {method: "assignUser", args: [createMockVariable("user")]},
                {method: "putFlash", args: [createMockString("info"), createMockString("Welcome")]},
                {method: "render", args: [createMockString("index.html")]}
            ]
        );
        
        var result = compiler.compileExpression(phoenixChain);
        
        // Should generate Phoenix-style pipes
        assertTrue(result.indexOf("|>") >= 0, "Should generate pipe operators");
        assertTrue(result.indexOf("assign(_, :user, user)") >= 0 ||
                  result.indexOf("Plug.Conn.assign(_, :user, user)") >= 0,
                  "Should convert assignUser to assign");
        assertTrue(result.indexOf("put_flash(_, :info, \"Welcome\")") >= 0,
                  "Should convert putFlash");
        assertTrue(result.indexOf("render(_, \"index.html\")") >= 0,
                  "Should handle render function");
        
        trace("✅ Phoenix pipe patterns test passed");
    }
    
    // Mock helper functions for pipe testing
    static function createMockChain(initial: Dynamic, methods: Array<String>) {
        return {
            expr: TChain(initial, methods.map(m -> {method: m, args: []}))
        };
    }
    
    static function createMockChainWithArgs(initial: Dynamic, calls: Array<{method: String, args: Array<Dynamic>}>) {
        return {
            expr: TChain(initial, calls)
        };
    }
    
    static function createMockComplexChain(initial: Dynamic, calls: Array<{method: String, args: Array<Dynamic>}>) {
        return {
            expr: TChain(initial, calls)
        };
    }
    
    static function createMockAnonymousPipe(initial: Dynamic, functions: Array<Dynamic>) {
        return {
            expr: TPipe(initial, functions)
        };
    }
    
    static function createMockEnumChain(initial: Dynamic, methods: Array<String>) {
        return {
            expr: TChain(initial, methods.map(m -> {method: m, args: [], isEnum: true}))
        };
    }
    
    static function createMockMapChain(initial: Dynamic, calls: Array<{method: String, args: Array<Dynamic>}>) {
        return {
            expr: TChain(initial, calls.map(c -> {method: c.method, args: c.args, isMap: true}))
        };
    }
    
    static function createMockPhoenixChain(initial: Dynamic, calls: Array<{method: String, args: Array<Dynamic>}>) {
        return {
            expr: TChain(initial, calls.map(c -> {method: c.method, args: c.args, isPhoenix: true}))
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
    
    static function createMockLambda(param: String, body: Dynamic) {
        return {
            expr: TFunction({args: [{name: param}], body: body})
        };
    }
    
    static function createMockLambda2(param1: String, param2: String, body: Dynamic) {
        return {
            expr: TFunction({args: [{name: param1}, {name: param2}], body: body})
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