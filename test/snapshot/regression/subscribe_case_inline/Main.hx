class Main {
    static function sub(): Result<Int, String> {
        // Simple function returning a Result to be used directly as a switch discriminant
        return Ok(42);
    }

    static function main() {
        // Repro: switch directly on function call result
        switch (sub()) {
            case Ok(v):
                trace("ok: " + v);
            case Error(e):
                trace("err: " + e);
        }
    }
}

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

