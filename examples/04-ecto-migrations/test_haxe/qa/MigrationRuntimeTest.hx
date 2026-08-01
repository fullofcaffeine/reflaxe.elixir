package qa;

import ecto.Migrator;
import elixir.Atom as ErlangAtom;
import elixir.types.Atom;
import elixir.types.Term;
import exunit.Assert.*;
import exunit.TestCase;

/** Proves generated migrations change a real database and can roll back. */
@:exunit
class MigrationRuntimeTest extends TestCase {
	static final TABLE_QUERY = "SELECT table_name " + "FROM information_schema.tables " + "WHERE table_schema = 'public' "
		+ "AND table_name IN ('posts', 'users') " + "ORDER BY table_name";

	@:test
	public function generatedMigrationsExecuteAndRollback():Void {
		var repo:Term = ErlangAtom.fromString("Elixir.EctoMigrationsExample.Repo");
		var migrated = EctoSQL.query(repo, TABLE_QUERY, []);

		// PostgreSQL's catalog is the independent oracle: both tables exist only
		// if Ecto successfully executed the Haxe-authored migrations above them.
		assertEqual([["posts"], ["users"]], migrated.rows);

		var migrationPath = ElixirSystem.fetchEnv("ECTO_MIGRATIONS_PATH");
		var options:Array<{_0:Atom, _1:Term}> = [{_0: "all", _1: true}];
		Migrator.run(repo, migrationPath, "down", options);

		var rolledBack = EctoSQL.query(repo, TABLE_QUERY, []);
		assertEqual(0, rolledBack.rows.length);
	}
}
