package elixir;

#if (macro || reflaxe_runtime || elixir)
/** Typed access to Elixir's `Bitwise` functions without importing operators. */
@:native("Bitwise")
extern class Bitwise {
	@:native("band") public static function band(left:Int, right:Int):Int;
}
#end
