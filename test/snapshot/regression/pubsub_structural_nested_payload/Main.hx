enum Option<T> {
    Some(value: T);
    None;
}

enum InnerMsg {
    Broadcast(msg: String);
}

enum OuterMsg {
    Wrap(inner: InnerMsg);
}

class Main {
    static var message: String = "hello";

    public static function main() {
        var _ = make(Some("x"));
    }

    static function make(opt: Option<String>): Option<OuterMsg> {
        return switch (opt) {
            case Some(x):
                // Touch binder to ensure it is kept as a real binder
                var keep = x;
                // Free var 'message' used in nested payload; pass should prefer binder 'x'
                Some(Wrap(Broadcast(message)));
            case None:
                None;
        }
    }
}
