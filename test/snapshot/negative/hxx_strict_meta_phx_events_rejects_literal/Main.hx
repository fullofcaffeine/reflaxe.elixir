package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

@:hxx_strict_phx_events
class Main {
    public static function render(assigns: Assigns): String {
        // Should fail under @:hxx_strict_phx_events: unknown literal phx-click values are disallowed.
        return HXX.hxx('<button phx-click="unknown_event">Save</button>');
    }

    public static function main() {}
}
