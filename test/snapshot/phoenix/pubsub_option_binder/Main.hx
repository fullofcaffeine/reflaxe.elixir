package;

// Minimal reproducer for Phoenix PubSub Option parsing + binder alignment
// Focus: {:some|:ok, binder} → {:some, level} when body uses `level`
// Also ensures Option constructors normalize to {:some, v} | :none in return paths.

enum Option<T> {
    Some(v: T);
    None;
}

class Main {
    static function parseLevel(payload: { level: Null<Int> }): Option<Int> {
        // Normalize: return Option shapes, not ok/error
        return switch (payload.level) {
            case null: None;
            case v: Some(v);
        };
    }

    // Switch-return, non-call context; enforce binder name `level`
    static function handle(payload: { level: Null<Int> }): Int {
        return switch (parseLevel(payload)) {
            case Some(level): level + 1;
            case None: 0;
        };
    }
}

