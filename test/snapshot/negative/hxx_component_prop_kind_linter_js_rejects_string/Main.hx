import HXX;
import phoenix.JS;

typedef CardAssigns = {
    js: JS,
    inner_content: String
}

@:component
class Components {
    @:component
    public static function card(assigns: CardAssigns): String {
        return hxx('<div>${assigns.inner_content}</div>');
    }
}

class Main {
    public static function render(assigns: {}): String {
        // Should fail: `js` expects a JS struct-like value (map), not a string.
        return hxx('<.card js="save">Hi</.card>');
    }

    public static function main(): Void {}
}

