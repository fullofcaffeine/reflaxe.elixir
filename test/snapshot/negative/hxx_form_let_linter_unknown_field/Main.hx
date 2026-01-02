package;

import HXX;

typedef Assigns = {
    var form: phoenix.Phoenix.Form<elixir.types.Term>;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <.form for={@form} :let={f}>
                <span><%= f.not_a_field %></span>
            </.form>
        ');
    }

    public static function main() {}
}
