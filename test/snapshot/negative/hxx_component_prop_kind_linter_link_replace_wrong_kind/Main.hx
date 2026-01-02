package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: `replace` expects Bool (e.g. replace={true}), not a string.
        return HXX.hxx('<.link href="/" replace="no">Hi</.link>');
    }

    public static function main() {}
}

