package elixir;

#if (macro || reflaxe_runtime || elixir)
import elixir.types.Term;

/** Typed access to Erlang's native `:binary` module. */
@:native(":binary")
extern class ErlangBinary {
	/** Return the first `{start, length}` match or `:nomatch`. */
	@:native("match")
	public static function match(subject:String, pattern:String):Term;

	/** Typed match result for callers that have already proved the pattern exists. */
	@:native("match")
	public static function matchFound(subject:String, pattern:String):{_0:Int, _1:Int};

	/** Return every `{start, length}` match for `pattern` in `subject`. */
	@:native("matches")
	public static function matches(subject:String, pattern:String):Array<Term>;
}
#end
