package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: :let is only valid on component tags and slot tags.
        return HXX.hxx('<div :let={x}>Hi</div>');
    }

    public static function main() {}
}

