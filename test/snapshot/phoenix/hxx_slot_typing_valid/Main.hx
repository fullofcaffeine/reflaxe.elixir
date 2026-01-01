package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<.card title="Hello"><:header label="Hello">Hi</:header></.card>');
    }

    public static function main() {}
}

