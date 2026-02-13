package server.infrastructure;

/**
 * Minimal Gettext shim so Phoenix web helpers can import ElixirFirstLiveviewWeb.Gettext.
 */
@:native("ElixirFirstLiveviewWeb.Gettext")
class Gettext {
	public static function gettext(message:String):String {
		return message;
	}
}
