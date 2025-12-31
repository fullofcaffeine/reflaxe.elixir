package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: user component `.card` does not allow unknown prop `unknown`.
        return HXX.hxx('<.card title="Hello" unknown="x">Hi</.card>');
    }

    public static function main() {}
}

