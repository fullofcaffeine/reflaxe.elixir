package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: <.card> does not define slot <:unknown>.
        return HXX.hxx('<.card title="Hello"><:unknown>Hi</:unknown></.card>');
    }

    public static function main() {}
}

