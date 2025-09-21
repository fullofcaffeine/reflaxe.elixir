/**
 * Test for enum variable extraction bug fix
 *
 * This test demonstrates the issue where idiomatic enum patterns
 * extract variables directly in the pattern match, but TVar nodes
 * still generate assignments from non-existent temp variables (like 'g').
 *
 * The bug causes generated Elixir code like:
 *   {:ok, value} ->
 *     value = g  # Error: undefined variable 'g'
 *     value
 */

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

enum Option<T> {
    Some(value: T);
    None;
}

class Main {
    static function main() {
        // Test Result enum patterns
        testResultUnwrapOr();
        testResultMap();

        // Test Option enum patterns
        testOptionUnwrap();
        testOptionMap();

        // Test nested patterns
        testNestedPatterns();
    }

    // Similar to ChangesetUtils.unwrap_or
    static function unwrapOr<T>(result: Result<T, String>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(reason): defaultValue;
        };
    }

    // Test mapping over Result
    static function mapResult<T, U>(result: Result<T, String>, fn: T -> U): Result<U, String> {
        return switch(result) {
            case Ok(value): Ok(fn(value));
            case Error(error): Error(error);
        };
    }

    // Similar to ChangesetUtils.to_option
    static function toOption<T>(result: Result<T, String>): Option<T> {
        return switch(result) {
            case Ok(value): Some(value);
            case Error(reason): None;
        };
    }

    // Test unwrapping Option
    static function unwrapOption<T>(option: Option<T>, defaultValue: T): T {
        return switch(option) {
            case Some(value): value;
            case None: defaultValue;
        };
    }

    // Test mapping over Option
    static function mapOption<T, U>(option: Option<T>, fn: T -> U): Option<U> {
        return switch(option) {
            case Some(value): Some(fn(value));
            case None: None;
        };
    }

    // Test nested enum patterns
    static function processNestedResult(result: Result<Option<Int>, String>): Int {
        return switch(result) {
            case Ok(Some(value)): value;
            case Ok(None): 0;
            case Error(msg): -1;
        };
    }

    // Test functions
    static function testResultUnwrapOr(): Void {
        var result1: Result<Int, String> = Ok(42);
        var result2: Result<Int, String> = Error("failed");

        var value1 = unwrapOr(result1, 0);
        var value2 = unwrapOr(result2, 0);

        trace('Result unwrapOr: $value1, $value2');
    }

    static function testResultMap(): Void {
        var result: Result<Int, String> = Ok(10);
        var mapped = mapResult(result, x -> x * 2);

        switch(mapped) {
            case Ok(value): trace('Mapped result: $value');
            case Error(error): trace('Error: $error');
        }
    }

    static function testOptionUnwrap(): Void {
        var option1: Option<String> = Some("hello");
        var option2: Option<String> = None;

        var value1 = unwrapOption(option1, "default");
        var value2 = unwrapOption(option2, "default");

        trace('Option unwrap: $value1, $value2');
    }

    static function testOptionMap(): Void {
        var option: Option<Int> = Some(5);
        var mapped = mapOption(option, x -> x + 10);

        switch(mapped) {
            case Some(value): trace('Mapped option: $value');
            case None: trace('None');
        }
    }

    static function testNestedPatterns(): Void {
        var nested1: Result<Option<Int>, String> = Ok(Some(100));
        var nested2: Result<Option<Int>, String> = Ok(None);
        var nested3: Result<Option<Int>, String> = Error("failed");

        var value1 = processNestedResult(nested1);
        var value2 = processNestedResult(nested2);
        var value3 = processNestedResult(nested3);

        trace('Nested patterns: $value1, $value2, $value3');
    }
}