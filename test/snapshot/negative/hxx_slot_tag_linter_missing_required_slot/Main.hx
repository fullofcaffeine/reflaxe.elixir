package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: required slot <:header> is missing.
        return HXX.hxx('<.card title="Hello">Hi</.card>');
    }

    public static function main() {}
}

