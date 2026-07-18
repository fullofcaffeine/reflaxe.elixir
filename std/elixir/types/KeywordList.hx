package elixir.types;

/**
 * A typed Elixir keyword list.
 *
 * Keyword lists are ordinary BEAM lists of `{atom, value}` tuples. Keeping that
 * representation explicit lets Haxe-authored Mix and OTP code use the native
 * target contract without confusing keyword lists with Haxe object maps.
 */
typedef KeywordList<T> = Array<{_0:Atom, _1:T}>;
