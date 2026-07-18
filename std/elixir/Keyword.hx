package elixir;

import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/** Type-safe externs for Elixir's `Keyword` module. */
@:native("Keyword")
extern class Keyword {
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
