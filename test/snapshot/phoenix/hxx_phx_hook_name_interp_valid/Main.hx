package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<div phx-hook=${HookName.Known}></div>');
    }

    public static function main() {}
}

