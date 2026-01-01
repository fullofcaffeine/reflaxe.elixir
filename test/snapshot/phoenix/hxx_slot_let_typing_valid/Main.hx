package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<.card title="Hello"><:header :let={h} label="Hi"><span class={h.user_name}><%= h.user_name %> (<%= h.count %>)</span></:header></.card>');
    }

    public static function main() {}
}

