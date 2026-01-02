package;

import HXX;

typedef Assigns = {
    var form: phoenix.Phoenix.Form<elixir.types.Term>;
}

class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('
            <.form for={@form} :let={f}>
                <span><%= f.id %> (<%= f.name %>) <%= f.data %></span>
            </.form>
        ');
    }

    public static function main() {}
}
