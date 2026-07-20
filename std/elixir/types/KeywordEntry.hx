package elixir.types;

/** One native `{atom, value}` entry in an Elixir keyword list. */
typedef KeywordEntry<T> = Tuple2<Atom, T>;
