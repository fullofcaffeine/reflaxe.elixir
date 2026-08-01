package qa;

import elixir.types.Term;

/**
 * Example-local target boundary for inspecting the real PostgreSQL schema.
 *
 * The migration is the behavior under test, so querying Ecto's SQL adapter is
 * the lowest faithful observer. Keeping this extern local avoids broadening the
 * public stdlib API merely to support one QA contract.
 */
@:native("Ecto.Adapters.SQL")
extern class EctoSQL {
	@:native("query!")
	static function query(repo:Term, sql:String, params:Array<Term>):SQLResult;
}

typedef SQLResult = {
	var rows:Array<Array<String>>;
}
