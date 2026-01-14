package;

import HXX;

typedef Assigns = {
    var event: String;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail under -D hxx_strict_phx_events: values must come from an event registry constant.
        return HXX.hxx('<button phx-click={@event}>OK</button>');
    }

    public static function main() {}
}

