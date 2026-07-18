package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Atom;
import elixir.types.Term;

/** Typed access to Erlang's cryptographic hash primitive. */
@:native(":crypto")
extern class Crypto {
	@:native("hash") public static function hash(algorithm:Atom, data:Term):Term;
}
#end
