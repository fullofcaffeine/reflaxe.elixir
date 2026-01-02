package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<.link navigate="/todos">Todos</.link>');
    }

    public static function main() {}
}

