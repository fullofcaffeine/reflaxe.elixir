package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: Phoenix requires phx-hook elements to have an id.
        return HXX.hxx('<div phx-hook="MyHook"></div>');
    }

    public static function main() {}
}

