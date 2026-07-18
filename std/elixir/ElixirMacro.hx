package elixir;

/**
 * Typed access to stable Elixir `Macro` naming helpers.
 *
 * These functions are useful to generators that need to map Mix application
 * and module names without embedding target code or duplicating Elixir's own
 * naming rules.
 */
@:native("Macro")
extern class ElixirMacro {
	/** Converts `my_app` to `MyApp`. */
	@:native("camelize")
	static function camelize(value:String):String;

	/** Converts `PreferenceStudio` to `preference_studio`. */
	@:native("underscore")
	static function underscore(value:String):String;
}
