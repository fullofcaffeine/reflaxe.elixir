package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;
import haxe.macro.Type.ClassType;
import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * ExUnitCompiler: Transforms Assert class method calls into ExUnit assertions
 * 
 * WHY: The Assert class provides type-safe test assertions in Haxe that need
 * to be compiled to idiomatic ExUnit assertion macros in Elixir.
 * 
 * WHAT: Detects calls to haxe.test.Assert methods and transforms them into
 * appropriate ExUnit macros (assert, refute, assert_raise, etc.)
 * 
 * HOW: Pattern matches on TCall expressions targeting Assert class methods,
 * extracts arguments, and generates EMacroCall AST nodes with proper ExUnit syntax.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles assertion transformation
 * - Open/Closed: New assertions can be added without modifying existing code
 * - Type Safety: Preserves Haxe's compile-time guarantees in test code
 * 
 * @see std/haxe/test/Assert.hx - The Assert API being compiled
 */
@:nullSafety(Off)
class ExUnitCompiler {
    
    /**
     * Compile an Assert method call to ExUnit assertion
     * 
     * WHY: Transform type-safe Haxe assertions to idiomatic ExUnit macros
     * WHAT: Converts Assert.method(...) to appropriate ExUnit assertion
     * HOW: Pattern matches on method name and generates corresponding macro
     * 
     * @param methodName The Assert method being called (e.g., "isTrue", "equals")
     * @param args The arguments passed to the Assert method
     * @return ElixirAST node representing the ExUnit assertion
     */
    public static function compileAssertion(methodName: String, args: Array<ElixirAST>): ElixirAST {
        #if debug_exunit_compiler
        trace('[XRay ExUnit] Compiling assertion: $methodName with ${args.length} args');
        for (i in 0...args.length) {
            var argStr = ElixirASTPrinter.printAST(args[i]);
            trace('[XRay ExUnit] Arg[$i]: $argStr');
        }
        #end
        
        // Handle different Assert methods
        switch (methodName) {
            case "isTrue":
                // Assert.isTrue(value, ?message) -> assert value, message
                return if (args.length > 1) {
                    makeAST(EMacroCall("assert", [args[0]], args[1]));
                } else {
                    makeAST(EMacroCall("assert", [args[0]], makeAST(ENil)));
                }
                
            case "isFalse":
                // Assert.isFalse(value, ?message) -> refute value, message
                return if (args.length > 1) {
                    makeAST(EMacroCall("refute", [args[0]], args[1]));
                } else {
                    makeAST(EMacroCall("refute", [args[0]], makeAST(ENil)));
                }
                
            case "equals":
                // Assert.equals(expected, actual, ?message) -> assert expected == actual, message
                if (args.length >= 2) {
                    var comparison = makeAST(EBinary(Equal, args[0], args[1]));
                    var message = args.length > 2 ? args[2] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [comparison], message));
                }
                return makeAST(ENil);
                
            case "notEquals":
                // Assert.notEquals(expected, actual, ?message) -> assert expected != actual, message
                if (args.length >= 2) {
                    var comparison = makeAST(EBinary(NotEqual, args[0], args[1]));
                    var message = args.length > 2 ? args[2] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [comparison], message));
                }
                return makeAST(ENil);
                
            case "isNull":
                // Assert.isNull(value, ?message) -> assert value == nil, message
                if (args.length >= 1) {
                    var comparison = makeAST(EBinary(Equal, args[0], makeAST(ENil)));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [comparison], message));
                }
                return makeAST(ENil);
                
            case "isNotNull":
                // Assert.isNotNull(value, ?message) -> assert value != nil, message
                if (args.length >= 1) {
                    var comparison = makeAST(EBinary(NotEqual, args[0], makeAST(ENil)));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [comparison], message));
                }
                return makeAST(ENil);
                
            case "isSome":
                // Assert.isSome(option, ?message) -> assert match?({:some, _}, option), message
                if (args.length >= 1) {
                    // Create pattern match for Option.Some
                    var pattern = makeAST(ETuple([
                        makeAST(EAtom(ElixirAtom.raw("some"))),
                        makeAST(EUnderscore)
                    ]));
                    var matchCall = makeAST(ECall(
                        null,
                        "match?",
                        [pattern, args[0]]
                    ));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [matchCall], message));
                }
                return makeAST(ENil);
                
            case "isNone":
                // Assert.isNone(option, ?message) -> assert option == :none, message
                if (args.length >= 1) {
                    var comparison = makeAST(EBinary(Equal, args[0], makeAST(EAtom(ElixirAtom.raw("none")))));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [comparison], message));
                }
                return makeAST(ENil);
                
            case "isOk":
                // Assert.isOk(result, ?message) -> assert match?({:ok, _}, result), message
                if (args.length >= 1) {
                    var pattern = makeAST(ETuple([
                        makeAST(EAtom(ElixirAtom.ok())),
                        makeAST(EUnderscore)
                    ]));
                    var matchCall = makeAST(ECall(
                        null,
                        "match?",
                        [pattern, args[0]]
                    ));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [matchCall], message));
                }
                return makeAST(ENil);
                
            case "isError":
                // Assert.isError(result, ?message) -> assert match?({:error, _}, result), message
                if (args.length >= 1) {
                    var pattern = makeAST(ETuple([
                        makeAST(EAtom(ElixirAtom.error())),
                        makeAST(EUnderscore)
                    ]));
                    var matchCall = makeAST(ECall(
                        null,
                        "match?",
                        [pattern, args[0]]
                    ));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [matchCall], message));
                }
                return makeAST(ENil);
                
            case "raises":
                // Assert.raises(fn, ?exceptionType, ?message) -> assert_raise ExceptionType, fn
                if (args.length >= 1) {
                    // For now, just use a general assert_raise without specific exception type
                    // TODO: Handle exception type parameter
                    return makeAST(EMacroCall("assert_raise", args, makeAST(ENil)));
                }
                return makeAST(ENil);
                
            case "doesNotRaise":
                // Assert.doesNotRaise(fn, ?message) -> fn.() (just execute, no assert needed)
                if (args.length >= 1) {
                    // Call the function with no arguments (anonymous function application)
                    return makeAST(ECall(args[0], "", []));
                }
                return makeAST(ENil);
                
            case "contains":
                // Assert.contains(collection, item, ?message) -> assert Enum.member?(collection, item), message
                if (args.length >= 2) {
                    var memberCall = makeAST(ECall(
                        makeAST(EField(
                            makeAST(EVar("Enum")),
                            "member?"
                        )),
                        "",
                        [args[0], args[1]]
                    ));
                    var message = args.length > 2 ? args[2] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [memberCall], message));
                }
                return makeAST(ENil);
                
            case "containsString":
                // Assert.containsString(haystack, needle, ?message) -> assert String.contains?(haystack, needle), message
                if (args.length >= 2) {
                    var containsCall = makeAST(ECall(
                        makeAST(EField(
                            makeAST(EVar("String")),
                            "contains?"
                        )),
                        "",
                        [args[0], args[1]]
                    ));
                    var message = args.length > 2 ? args[2] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [containsCall], message));
                }
                return makeAST(ENil);
                
            case "doesNotContainString":
                // Assert.doesNotContainString(haystack, needle, ?message) -> refute String.contains?(haystack, needle), message
                if (args.length >= 2) {
                    var containsCall = makeAST(ECall(
                        makeAST(EField(
                            makeAST(EVar("String")),
                            "contains?"
                        )),
                        "",
                        [args[0], args[1]]
                    ));
                    var message = args.length > 2 ? args[2] : makeAST(ENil);
                    return makeAST(EMacroCall("refute", [containsCall], message));
                }
                return makeAST(ENil);
                
            case "isEmpty":
                // Assert.isEmpty(collection, ?message) -> assert Enum.empty?(collection), message
                if (args.length >= 1) {
                    var emptyCall = makeAST(ECall(
                        makeAST(EField(
                            makeAST(EVar("Enum")),
                            "empty?"
                        )),
                        "",
                        [args[0]]
                    ));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [emptyCall], message));
                }
                return makeAST(ENil);
                
            case "isNotEmpty":
                // Assert.isNotEmpty(collection, ?message) -> refute Enum.empty?(collection), message
                if (args.length >= 1) {
                    var emptyCall = makeAST(ECall(
                        makeAST(EField(
                            makeAST(EVar("Enum")),
                            "empty?"
                        )),
                        "",
                        [args[0]]
                    ));
                    var message = args.length > 1 ? args[1] : makeAST(ENil);
                    return makeAST(EMacroCall("refute", [emptyCall], message));
                }
                return makeAST(ENil);
                
            case "inDelta":
                // Assert.inDelta(expected, actual, delta, ?message) -> assert_in_delta expected, actual, delta, message
                if (args.length >= 3) {
                    var deltaArgs = [args[0], args[1], args[2]];
                    var message = args.length > 3 ? args[3] : makeAST(ENil);
                    return makeAST(EMacroCall("assert_in_delta", deltaArgs, message));
                }
                return makeAST(ENil);
                
            case "fail":
                // Assert.fail(message) -> flunk(message)
                if (args.length >= 1) {
                    return makeAST(ECall(
                        null,
                        "flunk",
                        [args[0]]
                    ));
                }
                return makeAST(ENil);
                
            case "matches":
                // Assert.matches(pattern, value, ?message) -> assert match?(pattern, value), message
                if (args.length >= 2) {
                    var matchCall = makeAST(ECall(
                        null,
                        "match?",
                        [args[0], args[1]]
                    ));
                    var message = args.length > 2 ? args[2] : makeAST(ENil);
                    return makeAST(EMacroCall("assert", [matchCall], message));
                }
                return makeAST(ENil);
                
            case "received":
                // Assert.received(pattern, ?timeout, ?message) -> assert_received pattern, timeout
                if (args.length >= 1) {
                    // TODO: Handle timeout parameter properly
                    return makeAST(EMacroCall("assert_received", [args[0]], makeAST(ENil)));
                }
                return makeAST(ENil);
                
            default:
                #if debug_exunit_compiler
                trace('[XRay ExUnit] Unknown assertion method: $methodName');
                #end
                // Unknown assertion, just return nil
                return makeAST(ENil);
        }
    }
    
    /**
     * Check if a class reference is the Assert class
     * 
     * WHY: Need to identify Assert class calls in the AST
     * WHAT: Checks if a ClassType represents haxe.test.Assert
     * HOW: Compares pack and name to identify the Assert class
     * 
     * @param classType The class type to check
     * @return True if this is the Assert class
     */
    public static function isAssertClass(classType: ClassType): Bool {
        if (classType == null) return false;
        
        var pack = classType.pack.join(".");
        var name = classType.name;
        
        #if debug_exunit_compiler
        trace('[XRay ExUnit] Checking class: $pack.$name');
        #end
        
        return (pack == "haxe.test" && name == "Assert");
    }
}

#end