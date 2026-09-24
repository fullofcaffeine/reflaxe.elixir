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

		// Native catalog codes are independent of the compiler's action mapping:
		// PostgreSQL uses c for CASCADE on both deletion and key updates.
		var actions = EctoSQL.query(repo,
			"SELECT confdeltype::text, confupdtype::text FROM pg_constraint WHERE conrelid = 'posts'::regclass AND contype = 'f'", []);
		assertEqual([["c", "c"]], actions.rows);
		EctoSQL.query(repo, "INSERT INTO users (id, name, email, inserted_at, updated_at) VALUES (101, 'QA', 'qa@example.invalid', NOW(), NOW())", []);
		EctoSQL.query(repo, "INSERT INTO posts (title, user_id, inserted_at, updated_at) VALUES ('QA post', 101, NOW(), NOW())", []);
		EctoSQL.query(repo, "UPDATE users SET id = 102 WHERE id = 101", []);
		assertEqual([["102"]], EctoSQL.query(repo, "SELECT user_id::text FROM posts", []).rows);
		EctoSQL.query(repo, "DELETE FROM users WHERE id = 102", []);
		assertEqual([["0"]], EctoSQL.query(repo, "SELECT count(*)::text FROM posts", []).rows);

		// SQL catches only the expected database constraint violation. Any other
		// error, or an accepted invalid row, still fails this runtime contract.
		EctoSQL.query(repo,
			"DO $$ BEGIN BEGIN INSERT INTO posts (title, view_count, inserted_at, updated_at) " +
			"VALUES ('invalid', -1, NOW(), NOW()); RAISE EXCEPTION 'negative count was accepted'; " + "EXCEPTION WHEN check_violation THEN NULL; END; END $$",
			[]);

		// Independently specified runtime bytes: SQL quoting and target-looking text
		// are data, while the audit table proves the preceding inserts ran first.
		// Hex keeps the oracle independent of the compiler string printer under test.
		assertEqual([
			["6669727374"],
			[
				"71756f7465202720736c617368205c20696e746572706f6c6174696f6e20237b756e746f75636865647d"
			]
		],
			EctoSQL.query(repo, "SELECT encode(convert_to(label, 'UTF8'), 'hex') FROM execute_audit ORDER BY label", []).rows);

		// A repeated public ID is valid in different scopes. A child must match
		// both columns, and native catalog codes independently prove RESTRICT.
		EctoSQL.query(repo, "INSERT INTO scoped_parents (scope_id, public_id) VALUES (1, 'shared'), (2, 'shared'), (2, 'private')", []);
		EctoSQL.query(repo, "INSERT INTO scoped_children (\"scope-tag\", parent_key) VALUES (1, 'shared'), (2, 'shared')", []);
		assertEqual([["shared"], ["shared"]], EctoSQL.query(repo, "SELECT backup_key FROM scoped_children ORDER BY \"scope-tag\"", []).rows);
		assertEqual([["r", "r", "2"]],
			EctoSQL.query(repo, "SELECT confdeltype::text, confupdtype::text, cardinality(conkey)::text FROM pg_constraint WHERE conname='scoped_parent_key'",
				[])
				.rows);
		EctoSQL.query(repo,
			"DO $$ BEGIN BEGIN INSERT INTO scoped_children (\"scope-tag\", parent_key) VALUES (1, 'private'); RAISE EXCEPTION 'cross-scope reference accepted'; EXCEPTION WHEN foreign_key_violation THEN NULL; END; " +
			"BEGIN DELETE FROM scoped_parents WHERE scope_id=1 AND public_id='shared'; RAISE EXCEPTION 'referenced parent deletion accepted'; EXCEPTION WHEN foreign_key_violation THEN NULL; END; " +
			"BEGIN UPDATE scoped_parents SET scope_id=3 WHERE scope_id=1 AND public_id='shared'; RAISE EXCEPTION 'referenced scope update accepted'; EXCEPTION WHEN foreign_key_violation THEN NULL; END; END $$",
			[]);

		var migrationPath = ElixirSystem.fetchEnv("ECTO_MIGRATIONS_PATH");
		var options:Array<{_0:Atom, _1:Term}> = [{_0: "all", _1: true}];
		Migrator.run(repo, migrationPath, "down", options);

		var rolledBack = EctoSQL.query(repo, TABLE_QUERY, []);
		assertEqual(0, rolledBack.rows.length);
		assertEqual([["0"]],
			EctoSQL.query(repo,
				"SELECT count(*)::text FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('execute_records','execute_audit','scoped_children','scoped_parents')",
				[])
				.rows);
	}
}
