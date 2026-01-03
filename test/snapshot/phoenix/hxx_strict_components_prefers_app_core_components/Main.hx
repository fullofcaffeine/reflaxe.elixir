package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

@:native("AppAWeb.SomeLive")
class Main {
    public static function render(assigns: Assigns): String {
        // Must resolve to AppAWeb.CoreComponents.card/1 (not AppBWeb.CoreComponents.card/1).
        // In strict mode, this should still succeed when multiple candidates exist.
        return HXX.hxx('<.card title="Hello">Hi</.card>');
    }

    public static function main() {}
}
