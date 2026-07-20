package elixir;

import elixir.types.Atom;
import elixir.types.KeywordEntry;
import elixir.types.KeywordList;
import elixir.types.Term;

/** Type-safe externs for Elixir's `Keyword` module. */
@:native("Keyword")
extern class Keyword {
	/**
	 * Constructs one native `{atom, value}` keyword entry.
	 *
	 * This function is forced inline: generated Elixir contains only the tuple,
	 * never a `Keyword.entry/2` call or wrapper value.
	 */
	public static extern inline function entry<T>(key:Atom, value:T):KeywordEntry<T> {
		// Keep the parameter's Atom classification after Haxe substitutes the
		// caller expression into this forced-inline body. Without this typed cast,
		// a string literal can reach tuple lowering as a binary instead of an atom.
		return {_0: cast(key, Atom), _1: value};
	}

	/**
	 * Reads a typed value from a heterogeneous keyword list.
	 *
	 * The caller supplies the expected type through `defaultValue`; Elixir's
	 * `Keyword.get/3` returns that value unchanged.
	 */
	@:native("get")
	static function get<T>(keywords:KeywordList<Term>, key:Atom, defaultValue:T):T;

	@:native("has_key?")
	static function hasKey(keywords:KeywordList<Term>, key:Atom):Bool;

	@:native("put")
	static function put(keywords:KeywordList<Term>, key:Atom, value:Term):KeywordList<Term>;
}
