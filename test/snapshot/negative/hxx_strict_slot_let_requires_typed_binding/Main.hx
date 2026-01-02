package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<.card title="Hello" :let={row}><span>Hi</span></.card>');
    }

    public static function main() {}
}

