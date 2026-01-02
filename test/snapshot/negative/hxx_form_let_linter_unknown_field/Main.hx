package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <.form for={@ok} :let={f}>
                <span><%= f.not_a_field %></span>
            </.form>
        ');
    }

    public static function main() {}
}
