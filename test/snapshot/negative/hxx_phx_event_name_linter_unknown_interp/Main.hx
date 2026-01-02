package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: event name is not present in any @:phxEventNames registry.
        // NOTE: we use HEEx expression braces instead of Haxe string interpolation because Haxe
        // can constant-fold `${"literal"}` into a raw attribute string literal, which this linter
        // intentionally does not validate (to keep adoption gradual).
        return HXX.hxx('<button phx-click={"NotRegistered"}>X</button>');
    }

    public static function main() {}
}
