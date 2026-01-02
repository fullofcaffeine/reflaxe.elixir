package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail in strict mode: unknown dot component tag.
        return HXX.hxx('<.not_a_component>Hi</.not_a_component>');
    }

    public static function main() {}
}

