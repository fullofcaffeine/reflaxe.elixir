package;

import elixir.types.Term;

typedef Assigns = {
    var formFor: Term;
}

@:hxx_inline_markup
class Main {
    public static function render(assigns: Assigns): String {
        return <div>
            <.form :let={f} for=${assigns.formFor} action="/save">
                <div>
                    <input type="text" name="title" value=${f[:title].value}/>
                </div>
            </.form>
        </div>;
    }

    public static function main() {}
}
