package elixir.mix;

/**
 * The module selected by `Mix.shell/0`.
 *
 * `@:elixirModuleRef` tells Reflaxe.Elixir that this value is a BEAM module
 * reference. Instance-looking Haxe calls therefore become dynamic remote
 * calls such as `Mix.shell().info(message)` without a Haxe object receiver.
 */
@:elixirModuleRef
extern class Shell {
	function info(message:String):Void;

	function error(message:String):Void;

	@:native("yes?")
	function yes(message:String):Bool;
}
