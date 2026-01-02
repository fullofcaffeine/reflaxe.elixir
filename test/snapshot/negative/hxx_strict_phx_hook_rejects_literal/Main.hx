package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail under -D hxx_strict_phx_hook: literal phx-hook values are disallowed.
        return HXX.hxx('<div phx-hook="Known"></div>');
    }

    public static function main() {}
}

