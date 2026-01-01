package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: :let value must be a binding pattern (variable), not a string literal.
        return HXX.hxx('<.form :let="f" for="/submit">Hi</.form>');
    }

    public static function main() {}
}

