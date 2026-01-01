package myapp;

import haxe.functional.Result;

/**
 * Regression: Nested `switch` inside a `switch` case body with an `if` wrapper.
 *
 * The inner `switch` must scrutinee the *inner* Result expression, not the outer binder.
 */
class NestedSwitchResultInIf {
    static function outer(flag: Bool): Result<Int, String> {
        return flag ? Ok(1) : Error("nope");
    }

    static function inner(value: Int): Result<Int, String> {
        return value > 0 ? Ok(value + 1) : Error("bad");
    }

    public static function run(flag: Bool): Int {
        return switch (outer(flag)) {
            case Ok(v):
                if (v > 0) {
                    v;
                } else {
                    switch (inner(v)) {
                        case Ok(updated): updated;
                        case Error(_reason): 0;
                    }
                }
            case Error(_err):
                -1;
        }
    }

    public static function runInnerOnly(value: Int): Int {
        return switch (inner(value)) {
            case Ok(updated): updated;
            case Error(_reason): 0;
        }
    }
}

class Main {
    static function main() {
        var _ = NestedSwitchResultInIf.run(true);
        var _ = NestedSwitchResultInIf.runInnerOnly(1);
    }
}
