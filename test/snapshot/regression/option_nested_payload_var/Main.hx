enum Option<T> {
    Some(v:T);
    None;
}

class Main {
    public static function main() {}

    static function f(o:Option<String>): Option<Dynamic> {
        return switch (o) {
            case Some(level):
                Some({bulk_update: action}); // intentionally free var 'action'
            case None:
                None;
        }
    }
}

