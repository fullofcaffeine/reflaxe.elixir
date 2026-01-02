package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <.card title="Hello" :let={{row, idx}}>
                <span><%= row.user_name %> (<%= idx %>)</span>
            </.card>
        ');
    }

    public static function main() {}
}

