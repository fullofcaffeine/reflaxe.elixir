/**
 * Test and documentation for __elixir__() code injection mechanism
 * 
 * CRITICAL: Understanding __elixir__() Injection Syntax
 * ======================================================
 * 
 * The __elixir__() function allows injecting raw Elixir code into generated output.
 * However, it has specific requirements for how variables are substituted.
 * 
 * WHY $variable SYNTAX DOESN'T WORK:
 * -----------------------------------
 * When you write: untyped __elixir__('$x * 2')
 * 
 * Haxe's parser sees the $ and interprets this as STRING INTERPOLATION at compile-time.
 * This means Haxe tries to concatenate strings: "" + x + " * 2"
 * 
 * The result is that the TypedExpr becomes:
 *   TBinop(OpAdd, TConst(""), TBinop(OpAdd, TLocal(x), TConst(" * 2")))
 * 
 * This is NOT a constant string, so Reflaxe's TargetCodeInjection.checkTargetCodeInjection
 * cannot process it because it requires the first parameter to be TConst(TString(s)).
 * 
 * HOW {N} PLACEHOLDERS WORK:
 * ---------------------------
 * The correct syntax uses numbered placeholders: {0}, {1}, {2}, etc.
 * 
 * When you write: untyped __elixir__('{0} * 2', x)
 * 
 * 1. The first parameter IS a constant string: "{0} * 2"
 * 2. Reflaxe's injection system recognizes this pattern
 * 3. It compiles the variable x separately to get its Elixir representation
 * 4. It replaces {0} with the compiled result
 * 
 * RULES FOR __elixir__() USAGE:
 * ------------------------------
 * 1. First parameter MUST be a constant string literal (no concatenation)
 * 2. Use {0}, {1}, {2}... for variable substitution
 * 3. Variables are passed as additional parameters
 * 4. Variables are compiled to Elixir and substituted at their placeholder positions
 * 5. Keyword lists and atoms should be written directly in the string
 * 
 * EXAMPLES:
 * ---------
 * WRONG: untyped __elixir__('$x * 2')                    // $ causes string interpolation
 * WRONG: untyped __elixir__(myString)                    // Not a constant
 * WRONG: untyped __elixir__('func(' + x + ')')          // String concatenation
 * 
 * RIGHT: untyped __elixir__('{0} * 2', x)               // Placeholder substitution
 * RIGHT: untyped __elixir__('func({0}, {1})', a, b)     // Multiple variables
 * RIGHT: untyped __elixir__(':ok')                      // Direct atom injection
 * RIGHT: untyped __elixir__('[a: 1, b: 2]')            // Direct keyword list
 * 
 * @see https://github.com/SomeRanDev/reflaxe - Reflaxe documentation
 * @see reflaxe.compiler.TargetCodeInjection - The injection implementation
 */
class TestInjection {
    public static function testDirectInjection(): String {
        // Test 1: Simple string injection
        return untyped __elixir__('"Hello from Elixir"');
    }
    
    public static function testVariableSubstitution(): Int {
        // Test 2: Variable substitution in injection using {N} placeholders
        var x = 42;
        return untyped __elixir__('{0} * 2', x);
    }
    
    public static function testSupervisorCall() {
        // Test 3: What Telemetry needs - inject keyword list directly
        var children = [];
        // For keyword lists, inject them directly into the Elixir code
        return untyped __elixir__('Supervisor.start_link({0}, [strategy: :one_for_one, name: TestSupervisor])', children);
    }
    
    public static function testComplexInjection() {
        // Test 4: More complex injection with multiple variables
        var module = "TestModule";
        var func = "test_func";
        var args = [1, 2, 3];
        return untyped __elixir__('{0}.{1}({2})', module, func, args);
    }
}