package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        // Should fail: `h.not_a_field` is not declared on the slot :let binding type.
        return HXX.hxx('<.card title="Hello"><:header :let={h} label="Hi"><%= h.not_a_field %></:header></.card>');
    }

    public static function main() {}
}

