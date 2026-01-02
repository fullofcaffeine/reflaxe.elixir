package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: hook name is not present in any @:phxHookNames registry.
        // Uses string interpolation to cover common `phx-hook=${HookName.Name}` patterns.
        return HXX.hxx('<div phx-hook=${"NotRegistered"}></div>');
    }

    public static function main() {}
}

