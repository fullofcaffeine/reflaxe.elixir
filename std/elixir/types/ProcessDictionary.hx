package elixir.types;

/**
 * ProcessDictionary
 *
 * Represents the process dictionary returned by `Process.get/0`.
 *
 * Keys and values in the process dictionary are arbitrary Elixir terms, so this
 * type uses `Term` at the boundary while still accurately modeling the runtime shape.
 */
typedef ProcessDictionary = Map<Term, Term>;
