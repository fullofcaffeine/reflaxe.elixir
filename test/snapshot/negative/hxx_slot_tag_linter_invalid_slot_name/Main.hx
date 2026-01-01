package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: slot tag names must be identifiers (no dashes).
        return HXX.hxx('<.link navigate="/foo"><:bad-name>Hi</:bad-name></.link>');
    }

    public static function main() {}
}

