package;

import HXX;

typedef Assigns = {
	var name:String;
}

@:hxx_strict_attr_values
@:hxx_mode("balanced")
class Main {
	public static function render(assigns:Assigns):String {
		return HXX.hxx('
            <form method="post" phx-update="replace">
                <input type="email" />
                <button type="submit">Save</button>
                <textarea wrap="hard"></textarea>
            </form>
        ');
	}

	public static function main() {}
}
