package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: module component `Test.Components.card` does not allow unknown prop `unknown`.
        return HXX.hxx('<Test.Components.card title="Hello" unknown="x">Hi</Test.Components.card>');
    }

    public static function main() {}
}

