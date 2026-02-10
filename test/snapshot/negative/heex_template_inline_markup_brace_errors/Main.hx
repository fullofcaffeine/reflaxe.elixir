package;

typedef Assigns = {
    var count: Int;
}

@:liveview
class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: unterminated `${...}` segment in inline markup.
        return <div>${assigns.count</div>;
    }

    public static function main() {}
}

