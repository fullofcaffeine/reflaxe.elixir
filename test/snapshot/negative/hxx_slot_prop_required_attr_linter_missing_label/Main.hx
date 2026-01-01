package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: <:header> is missing required prop `label`.
        return HXX.hxx('<.card title="Hello"><:header>Hi</:header></.card>');
    }

    public static function main() {}
}

