package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: hook name is not present in any @:phxHookNames registry.
        // Parens force a non-trivial HEEx attribute expression shape.
        return HXX.hxx('<div phx-hook={("NotRegistered")}></div>');
    }

    public static function main() {}
}

