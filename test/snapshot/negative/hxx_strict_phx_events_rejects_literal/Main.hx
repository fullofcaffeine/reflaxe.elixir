package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail under -D hxx_strict_phx_events: literal phx-click values are disallowed.
        return HXX.hxx('<button phx-click="save">Save</button>');
    }

    public static function main() {}
}

