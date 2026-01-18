package;

typedef Assigns = {
    var ok: Bool;
}

@:hxx_inline_markup
class Main {
    public static function render(assigns: Assigns): String {
        return <button phx-click=${EventName.Save}>Save</button>;
    }

    public static function main() {}
}

