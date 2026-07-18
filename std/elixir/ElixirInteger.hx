package elixir;

#if (macro || reflaxe_runtime || elixir)
/** Typed access to Elixir's `Integer` module. */
@:native("Integer")
extern class ElixirInteger {
	@:native("to_string") public static function toString(value:Int):String;
}
#end
