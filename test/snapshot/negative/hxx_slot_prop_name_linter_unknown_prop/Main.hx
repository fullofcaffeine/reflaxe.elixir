package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: <:header> does not allow unknown prop `unknown`.
        return HXX.hxx('<.card title="Hello"><:header label="Hello" unknown="x">Hi</:header></.card>');
    }

    public static function main() {}
}

