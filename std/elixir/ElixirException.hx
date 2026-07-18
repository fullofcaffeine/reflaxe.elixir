package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;

/** Typed access to Elixir's native `Exception` protocol helpers. */
@:native("Exception")
extern class ElixirException {
	@:native("message")
	public static function message<T>(exception:T):String;
}
#end
