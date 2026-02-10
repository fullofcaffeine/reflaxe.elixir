package;

typedef Assigns = {
    var count: Int;
}

@:liveview
class Main {
    public static function render(assigns: Assigns): String {
        // Should fail by default: raw HEEx markers bypass HXX typing.
        return <div>count: <%= @count %></div>;
    }

    public static function main() {}
}

