package;

import HXX;

typedef Assigns = {
    var any: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: misspelled `.form` prop `for`.
        return HXX.hxx('<.form :let={_f} forr="oops"></.form>');
    }

    public static function main() {}
}

