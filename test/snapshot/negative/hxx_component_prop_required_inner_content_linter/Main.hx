package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: `.card` requires inner content but tag has no meaningful children.
        return HXX.hxx('<.card title="Hello"></.card>');
    }

    public static function main() {}
}

