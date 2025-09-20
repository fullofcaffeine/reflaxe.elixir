/**
 * Regression test for EverythingIsExprSanitizer switch expression bug
 *
 * ISSUE: When a static method returns a switch expression directly,
 * the Reflaxe preprocessor EverythingIsExprSanitizer incorrectly
 * transforms the code, losing the switch body and replacing it
 * with just one of the case variables (e.g., "value").
 *
 * This causes undefined variable errors in the generated Elixir code.
 *
 * Expected: Proper case expressions should be generated
 * Actual: temp_result = value (where value is undefined)
 *
 * See: docs/03-compiler-development/EVERYTHINGISEXPR_SANITIZER_ISSUE.md
 */

// Result type for testing
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

// Option type for testing
enum Option<T> {
    Some(value: T);
    None;
}

class SwitchReturnTest {
    public function new() {}

    /**
     * FAILS: Static method returning switch on Result directly
     * This is the primary bug case - generates undefined "value"
     */
    public static function unwrapOr<T>(result: Result<T, String>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }

    /**
     * FAILS: Static method returning switch on Option directly
     * Another case that triggers the bug
     */
    public static function getOrElse<T>(option: Option<T>, defaultValue: T): T {
        return switch(option) {
            case Some(value): value;
            case None: defaultValue;
        };
    }

    /**
     * FAILS: Static method with nested switch expression
     * More complex case to ensure our fix handles nesting
     */
    public static function nestedSwitch<T>(outer: Option<Result<T, String>>, defaultValue: T): T {
        return switch(outer) {
            case Some(result): switch(result) {
                case Ok(value): value;
                case Error(_): defaultValue;
            };
            case None: defaultValue;
        };
    }

    /**
     * WORKS: Instance method returning switch (for comparison)
     * Instance methods might follow a different code path
     */
    public function instanceUnwrapOr<T>(result: Result<T, String>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }

    /**
     * WORKS: Static method with explicit temp variable
     * This is the workaround pattern that avoids the bug
     */
    public static function workingUnwrapOr<T>(result: Result<T, String>, defaultValue: T): T {
        var output = switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
        return output;
    }

    /**
     * FAILS: Static method with switch in expression position
     * Tests if the bug affects switches used as expressions
     */
    public static function mapOrElse<T, U>(
        result: Result<T, String>,
        mapFn: (T) -> U,
        elseFn: () -> U
    ): U {
        return switch(result) {
            case Ok(value): mapFn(value);
            case Error(_): elseFn();
        };
    }
}

class Main {
    static function main() {
        // Test cases to verify the generated code compiles
        var testResult: Result<Int, String> = Ok(42);
        var testOption: Option<String> = Some("hello");

        // These should all work at runtime (if the bug is fixed)
        var r1 = SwitchReturnTest.unwrapOr(testResult, 0);
        var r2 = SwitchReturnTest.getOrElse(testOption, "default");
        var r3 = SwitchReturnTest.nestedSwitch(Some(Ok(100)), 0);
        var r4 = SwitchReturnTest.workingUnwrapOr(testResult, 0);
        var r5 = SwitchReturnTest.mapOrElse(
            testResult,
            function(x) return x * 2,
            function() return -1
        );

        // Instance method test
        var instance = new SwitchReturnTest();
        var r6 = instance.instanceUnwrapOr(testResult, 0);

        trace("All tests executed");
    }
}