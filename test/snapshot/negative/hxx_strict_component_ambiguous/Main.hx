package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail in strict mode: multiple @:component functions named `card` exist.
        return HXX.hxx('<.card title="Hello">Hi</.card>');
    }

    public static function main() {}
}

