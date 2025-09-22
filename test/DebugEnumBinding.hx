package;

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class DebugEnumBinding {
    public static function main() {
        var result: Result<String, String> = Error("test error");

        // This should generate proper pattern matching
        var output = switch(result) {
            case Ok(value):
                value;
            case Error(_):  // Ignored parameter - this is the problematic case
                "default";
        };

        trace(output);
    }

    // Another test case similar to ChangesetUtils
    public static function unwrapOr<T>(result: Result<T, String>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;  // Ignored error parameter
        };
    }
}