package;

import HXX;

typedef Assigns = {
    var any: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: misspelled `.link` prop `navigate`.
        return HXX.hxx('<.link naviate="/foo">Go</.link>');
    }

    public static function main() {}
}

