package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;

/** Typed access to Erlang filesystem error formatting. */
@:native(":file")
extern class ErlangFile {
	@:native("format_error")
	public static function formatError(reason:Term):String;
}
#end
