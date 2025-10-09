class Main {
    static function sub(): Result<Int, String> {
        // Flip between Ok and Error to exercise both branches
        return Ok(7);
    }

    static function mount(): Result<Int, String> {
        // Pattern similar to TodoLive.mount: early return on Error, continue on Ok
        switch (sub()) {
            case Ok(_):
                // continue
            case Error(reason):
                return Error("Failed: " + reason);
        }
        // Continue normal flow
        return Ok(1);
    }

    static function main() {
        var r = mount();
        switch (r) {
            case Ok(v): trace("ok: " + v);
            case Error(e): trace("err: " + e);
        }
    }
}

enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

