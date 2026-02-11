package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

@:hxx_strict_phx_hook
class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<div id="hook-root" phx-hook=${HookName.Ping}>Connected</div>');
    }

    public static function main() {}
}
