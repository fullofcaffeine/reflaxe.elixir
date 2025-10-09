class Main {
    static function update(): Result<Int, String> {
        return Ok(456);
    }

    static function broadcast(): Result<Int, String> {
        return Ok(1);
    }

    static function main() {
        switch (update()) {
            case Ok(_todo):
                // Nested switch on a function call in a branch
                switch (broadcast()) {
                    case Ok(_):
                        trace("ok");
                    case Error(e):
                        trace("err:" + e);
                }
            case Error(e):
                trace("err:" + e);
        }
    }
}

enum Result<T, E> {
    Ok(v:T);
    Error(e:E);
}

