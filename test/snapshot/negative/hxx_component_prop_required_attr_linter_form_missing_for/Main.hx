package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: `.form` requires the `for` attribute.
        return HXX.hxx('<.form :let={_f} action="/submit">Hi</.form>');
    }

    public static function main() {}
}

