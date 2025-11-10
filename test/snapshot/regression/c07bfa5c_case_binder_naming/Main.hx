/**
 * Regression snapshot for c07bfa5c
 *
 * Focus: case binder/body consistency and camelCase leaks.
 * - unwrapOr: {:ok, value} should use value directly; {:error, _} returns defaultValue
 * - toOption: maps Ok(value) -> Some(value); Error(_) -> None
 * Expectation in Elixir: no `value = g`, no camelCase identifiers in output.
 */

@:elixirIdiomatic
enum Result<T,E> {
    Ok(value:T);
    Error(reason:E);
}

@:elixirIdiomatic
enum Option<T> {
    Some(value:T);
    None;
}

class Main {
    // Keep private to generate defp in Elixir (matches other snapshots)
    static function unwrapOr(result:Result<Int,String>, defaultValue:Int):Int {
        return switch (result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }

    static function toOption(result:Result<Int,String>):Option<Int> {
        return switch (result) {
            case Ok(value): Some(value);
            case Error(_): None;
        };
    }

    public static function main() {
        var r1:Result<Int,String> = Ok(42);
        var r2:Result<Int,String> = Error("x");
        unwrapOr(r1, 0);
        unwrapOr(r2, 0);
        toOption(r1);
        toOption(r2);
    }
}

