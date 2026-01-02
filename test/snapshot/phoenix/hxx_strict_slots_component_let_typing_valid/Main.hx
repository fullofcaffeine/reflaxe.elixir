package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<.card title="Hello" :let={row}><span class={row.user_name}><%= row.user_name %> (<%= row.count %>)</span></.card>');
    }

    public static function main() {}
}
