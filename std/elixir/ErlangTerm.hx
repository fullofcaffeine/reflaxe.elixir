package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;

/** Typed access to Erlang's lossless external-term codec. */
@:native(":erlang")
extern class ErlangTerm {
	/** Encode a trusted BEAM term as an opaque binary. */
	@:native("term_to_binary")
	public static function toBinary(value:Term):String;

	/** Decode an opaque binary produced by `term_to_binary/1`. */
	@:native("binary_to_term")
	public static function fromBinary(value:String):Term;
}
#end
