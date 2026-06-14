package;

import HXX;

typedef Assigns = {
	var field:{};
}

@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		return HXX.hxx('
            <.inputs_for field={@field} :let={f}>
                <span>#{f.id} (#{f.index})</span>
            </.inputs_for>
        ');
	}

	public static function main() {}
}
