package server.infrastructure;

/**
 * Minimal Gettext shim so Phoenix web helpers can import ElixirFirstLiveviewWeb.Gettext.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("ElixirFirstLiveviewWeb.Gettext")
class Gettext {
	public static function gettext(message:String):String {
		return message;
	}
}
