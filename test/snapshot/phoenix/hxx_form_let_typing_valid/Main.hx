package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <.form for={@ok} :let={f}>
                <span><%= f.id %> (<%= f.name %>) <%= f.data %></span>
            </.form>
        ');
    }

    public static function main() {}
}
