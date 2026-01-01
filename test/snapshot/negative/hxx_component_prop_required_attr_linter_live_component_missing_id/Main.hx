package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: <.live_component> requires an `id`.
        return HXX.hxx('<.live_component module="MyComponent"></.live_component>');
    }

    public static function main() {}
}
