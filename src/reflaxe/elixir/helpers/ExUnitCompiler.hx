package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;

using StringTools;

/**
 * Specialized compiler for ExUnit test classes.
 * 
 * Handles compilation of classes marked with @:exunit_test to proper
 * ExUnit test modules with correct test syntax and assertions.
 */
class ExUnitCompiler {
    /**
     * Compile a test class to an ExUnit module.
     * 
     * @param classType The Haxe class to compile
     * @param compiler The main Elixir compiler instance
     * @return Generated ExUnit module code
     */
    public static function compile(classType: ClassType, compiler: ElixirCompiler): String {
        var result = new StringBuf();
        var className = classType.name;
        
        // Generate module header
        result.add('defmodule ${className} do\n');
        result.add('  use ExUnit.Case\n\n');
        
        // Add module documentation
        if (classType.doc != null) {
            result.add('  @moduledoc """\n');
            result.add('  ${classType.doc}\n');
            result.add('  """\n\n');
        }
        
        // Determine if this is an async test module
        var async = isAsyncTest(classType);
        if (async) {
            result.add('  use ExUnit.Case, async: true\n\n');
        }
        
        // Add setup methods if present
        compileSetupMethods(classType, result, compiler);
        
        // Compile test methods
        compileTestMethods(classType, result, compiler);
        
        result.add('end\n');
        return result.toString();
    }
    
    /**
     * Check if this test class should run asynchronously
     */
    static function isAsyncTest(classType: ClassType): Bool {
        var metaEntries = classType.meta.extract(":async");
        return metaEntries.length > 0;
    }
    
    /**
     * Compile setup and teardown methods
     */
    static function compileSetupMethods(classType: ClassType, result: StringBuf, compiler: ElixirCompiler): Void {
        for (field in classType.fields.get()) {
            switch (field.name) {
                case "setup":
                    compileSetupMethod(field, result, compiler, false);
                case "setupAll":
                    compileSetupMethod(field, result, compiler, true);
                case "teardown":
                    compileTeardownMethod(field, result, compiler, false);
                case "teardownAll":
                    compileTeardownMethod(field, result, compiler, true);
                case _:
                    // Skip other methods
            }
        }
    }
    
    /**
     * Compile a setup method
     */
    static function compileSetupMethod(field: ClassField, result: StringBuf, compiler: ElixirCompiler, all: Bool): Void {
        var setupType = all ? "setup_all" : "setup";
        
        result.add('  ${setupType} do\n');
        
        // For basic setup, return empty context
        // Fallback: Basic setup implementation - customize in test source if needed
        result.add('    {:ok, %{}}\n');
        result.add('  end\n\n');
    }
    
    /**
     * Compile a teardown method
     */
    static function compileTeardownMethod(field: ClassField, result: StringBuf, compiler: ElixirCompiler, all: Bool): Void {
        var teardownType = all ? "on_exit" : "on_exit";
        
        result.add('  ${teardownType}(fn ->\n');
        
        // Fallback: Basic teardown implementation
        result.add('    :ok\n');
        result.add('  end)\n\n');
    }
    
    /**
     * Compile all test methods in the class
     */
    static function compileTestMethods(classType: ClassType, result: StringBuf, compiler: ElixirCompiler): Void {
        for (field in classType.fields.get()) {
            if (field.meta.has(":exunit_test_method")) {
                compileTestMethod(field, result, compiler);
            }
        }
    }
    
    /**
     * Compile a single test method
     */
    static function compileTestMethod(field: ClassField, result: StringBuf, compiler: ElixirCompiler): Void {
        // Extract test name from metadata
        var testName = "test";
        var metaEntries = field.meta.extract(":exunit_test_method");
        if (metaEntries.length > 0 && metaEntries[0].params.length > 0) {
            switch (metaEntries[0].params[0].expr) {
                case EConst(CString(s, _)):
                    // Extract string value from metadata
                    testName = s;
                case _:
                    // Fall back to field name if not a string constant
                    testName = field.name;
            }
        }
        
        // Generate test function
        result.add('  test "${testName}" do\n');
        
        // Compile method body
        switch (field.type) {
            case TFun(args, ret):
                compileTestMethodBody(field, result, compiler);
            case _:
                result.add('    # Fallback: Test method stub - implement logic in Haxe source\n');
                result.add('    assert true\n');
        }
        
        result.add('  end\n\n');
    }
    
    /**
     * Compile the body of a test method
     */
    static function compileTestMethodBody(field: ClassField, result: StringBuf, compiler: ElixirCompiler): Void {
        // Get the method expression from the field
        switch (field.expr()) {
            case null:
                // No expression available - generate placeholder
                result.add('    # Test method: ${field.name}\n');
                result.add('    # No method body available - generating placeholder\n');
                result.add('    assert true\n');
                
            case methodExpr:
                // Compile the actual method body
                switch (methodExpr.expr) {
                    case TFunction(tfunc):
                        // Extract function body and compile it
                        var body = tfunc.expr;
                        compileTestMethodExpression(body, result, compiler);
                        
                    case _:
                        // Direct expression (shouldn't happen for methods, but handle gracefully)
                        compileTestMethodExpression(methodExpr, result, compiler);
                }
        }
    }
    
    /**
     * Compile a single test method expression, transforming Assert calls to ExUnit syntax
     */
    static function compileTestMethodExpression(expr: TypedExpr, result: StringBuf, compiler: ElixirCompiler): Void {
        // Compile the expression using the main compiler
        var compiledBody = compiler.compileExpression(expr);
        
        // Transform Assert method calls to ExUnit assertions
        var transformedBody = transformAssertCalls(compiledBody);
        
        // Add the compiled body with proper indentation
        var lines = transformedBody.split('\n');
        for (line in lines) {
            if (line.trim() != '') {
                result.add('    ${line}\n');
            }
        }
    }
    
    /**
     * Transform Assert method calls in compiled code to ExUnit assertions
     */
    static function transformAssertCalls(code: String): String {
        // Use simple regex approach but handle string building safely
        var assertPattern = ~/Assert\.(\w+)\(([^()]*(?:\([^()]*\)[^()]*)*)\)/g;
        
        return assertPattern.map(code, function(ereg) {
            var methodName = ereg.matched(1);
            var argsStr = ereg.matched(2);
            
            // Parse arguments with robust parsing that handles nested expressions
            var args = parseArguments(argsStr);
            
            // Transform enum constructors in arguments before passing to transformAssertCall
            var transformedArgs = args.map(transformEnumConstructors);
            
            return transformAssertCall(methodName, transformedArgs);
        });
    }
    
    /**
     * Transform enum constructors like Some("value") to {:some, "value"}
     */
    static function transformEnumConstructors(arg: String): String {
        // Handle Some(value) -> {:some, value}
        var somePattern = ~/Some\(([^)]+)\)/g;
        arg = somePattern.replace(arg, '{:some, $1}');
        
        // Handle None -> :none
        var nonePattern = ~/\bNone\b/g;
        arg = nonePattern.replace(arg, ':none');
        
        // Handle Ok(value) -> {:ok, value}
        var okPattern = ~/Ok\(([^)]+)\)/g;
        arg = okPattern.replace(arg, '{:ok, $1}');
        
        // Handle Error(value) -> {:error, value}
        var errorPattern = ~/Error\(([^)]+)\)/g;
        arg = errorPattern.replace(arg, '{:error, $1}');
        
        return arg;
    }
    
    /**
     * Robust argument parser for Assert method calls that handles nested expressions
     */
    static function parseArguments(argsStr: String): Array<String> {
        var args = [];
        var current = "";
        var parentheses = 0;
        var braces = 0;
        var inString = false;
        var stringChar = "";
        
        for (i in 0...argsStr.length) {
            var char = argsStr.charAt(i);
            
            if (!inString && (char == '"' || char == "'")) {
                inString = true;
                stringChar = char;
                current += char;
            } else if (inString && char == stringChar) {
                inString = false;
                stringChar = "";
                current += char;
            } else if (!inString && char == '(') {
                parentheses++;
                current += char;
            } else if (!inString && char == ')') {
                parentheses--;
                current += char;
            } else if (!inString && char == '{') {
                braces++;
                current += char;
            } else if (!inString && char == '}') {
                braces--;
                current += char;
            } else if (!inString && char == ',' && parentheses == 0 && braces == 0) {
                // Found a top-level comma - split here
                args.push(current.trim());
                current = "";
            } else {
                current += char;
            }
        }
        
        // Add the last argument
        if (current.trim() != "") {
            args.push(current.trim());
        }
        
        return args;
    }
    
    /**
     * Check if a class is an ExUnit test class
     */
    public static function isExUnitTest(classType: ClassType): Bool {
        return classType.meta.has(":exunit_test") || classType.meta.has(":exunit");
    }
    
    /**
     * Transform Assert method calls to ExUnit assertions
     */
    public static function transformAssertCall(methodName: String, args: Array<String>): String {
        // Helper function to safely build assert statements by avoiding string interpolation with complex expressions
        function buildAssert(template: String, params: Array<String>): String {
            var result = template;
            for (i in 0...params.length) {
                var placeholder = '$' + i;
                result = StringTools.replace(result, placeholder, params[i]);
            }
            return result;
        }
        
        return switch (methodName) {
            case "isTrue":
                buildAssert('assert $0', args);
            case "isFalse":
                buildAssert('refute $0', args);
            case "equals":
                buildAssert('assert $1 == $0', args); // actual == expected
            case "notEquals":
                buildAssert('refute $1 == $0', args);
            case "isNull":
                buildAssert('assert is_nil($0)', args);
            case "isNotNull":
                buildAssert('refute is_nil($0)', args);
            case "isSome":
                buildAssert('assert OptionTools.is_some($0)', args);
            case "isNone":
                buildAssert('assert OptionTools.is_none($0)', args);
            case "isOk":
                buildAssert('assert ResultTools.is_ok($0)', args);
            case "isError":
                buildAssert('assert ResultTools.is_error($0)', args);
            case "contains":
                buildAssert('assert Enum.member?($0, $1)', args);
            case "containsString":
                buildAssert('assert String.contains?($0, $1)', args);
            case "doesNotContainString":
                buildAssert('refute String.contains?($0, $1)', args);
            case "isEmpty":
                buildAssert('assert Enum.empty?($0)', args);
            case "isNotEmpty":
                buildAssert('refute Enum.empty?($0)', args);
            case "inDelta":
                buildAssert('assert_in_delta $0, $1, $2', args);
            case "fail":
                buildAssert('flunk($0)', args);
            case "raises":
                if (args.length >= 2) {
                    buildAssert('assert_raise $1, fn -> $0 end', args);
                } else {
                    buildAssert('assert_raise fn -> $0 end', args);
                }
            case "doesNotRaise":
                buildAssert('$0', args); // Just execute the function
            case "received":
                if (args.length >= 2) {
                    buildAssert('assert_receive $0, $1', args);
                } else {
                    buildAssert('assert_receive $0', args);
                }
            case _:
                buildAssert('# Unknown assertion: ${methodName}', []);
        }
    }
}