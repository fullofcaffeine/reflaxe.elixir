enum Option<T> {
    Some(value: T);
    None;
}

class Main {
    public static function main() {}

    static function value(opt: Option<Int>): Int {
        return switch (opt) {
            case Some(level):
                // Binder 'level' is intentionally unused in body
                1;
            case None:
                0;
        }
    }
}

