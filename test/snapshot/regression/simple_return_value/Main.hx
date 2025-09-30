package;

abstract Changeset<T>(Dynamic) {
    public inline function new(x: Dynamic) {
        this = x;
    }

    @:from
    public static inline function from<T>(x: Dynamic): Changeset<T> {
        return new Changeset(x);
    }
}

class Main {
    public static function main() {
        trace(changeset(null, {}));
    }

    static function changeset(user: Dynamic, attrs: Dynamic): Changeset<Dynamic> {
        var changeset = new Changeset(user);
        return changeset;
    }
}