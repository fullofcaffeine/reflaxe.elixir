package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.KeywordList;
import elixir.types.Term;

/** Typed access to Elixir's binary base encoders. */
@:native("Base")
extern class Base {
	@:native("encode16") public static function encode16(data:Term, options:KeywordList<Term>):String;
}
#end
