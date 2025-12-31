package;

import HXX;

typedef Assigns = {
    var any: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: misspelled `placeholder` attribute.
        return HXX.hxx('<div><input placehoder="Email" /></div>');
    }

    public static function main() {}
}

