package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <.inputs_for field={@ok} :let={f}>
                <span><%= f.not_a_field %></span>
            </.inputs_for>
        ');
    }

    public static function main() {}
}
