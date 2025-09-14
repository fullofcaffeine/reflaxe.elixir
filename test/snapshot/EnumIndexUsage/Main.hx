/**
 * Test for TEnumIndex usage detection in UsageDetector
 *
 * This test verifies that when Haxe transforms switch statements on enums
 * to use TEnumIndex (checking enum index), the UsageDetector correctly
 * detects that the enum variable is being used and doesn't prefix it
 * with underscore.
 */

enum Result<T, E> {
    Ok(value: T);
    Error(reason: E);
}

class Main {
    static function unwrapOr<T>(result: Result<T, String>, defaultValue: T): T {
        // Haxe transforms this switch to use TEnumIndex internally
        // to check the enum's integer index for optimization
        return switch(result) {
            case Ok(value):
                value;
            case Error(_):
                defaultValue;
        }
    }

    static function toOption<T>(result: Result<T, String>): Null<T> {
        return switch(result) {
            case Ok(value):
                value;
            case Error(_):
                null;
        }
    }

    static function main() {
        var result: Result<Int, String> = Ok(42);
        var value = unwrapOr(result, 0);
        trace("Value: " + value);

        var option = toOption(result);
        trace("Option: " + option);

        var errorResult: Result<Int, String> = Error("Something went wrong");
        var fallback = unwrapOr(errorResult, -1);
        trace("Fallback: " + fallback);
    }
}