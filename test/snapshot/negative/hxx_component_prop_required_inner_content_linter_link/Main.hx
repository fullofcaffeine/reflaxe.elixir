package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: <.link> requires inner content.
        return HXX.hxx('<.link href="/"></.link>');
    }

    public static function main() {}
}

