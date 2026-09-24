defmodule EctoMigrationsExample.MigrationRuntimeTest do
  use ExUnit.Case
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, EctoMigrationsExample.MigrationRuntimeTest, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, EctoMigrationsExample.MigrationRuntimeTest, key}
    Process.put(static_key, {:set, value})
    value
  end
  def table_query() do
    __haxe_static_get__(:table_query, "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('posts', 'users') ORDER BY table_name")
  end
  def table_query(value) do
    __haxe_static_put__(:table_query, value)
  end
  test "generated migrations execute and rollback" do
    repo = :erlang.binary_to_atom("Elixir.EctoMigrationsExample.Repo")
    migrated = Ecto.Adapters.SQL.query!(repo, EctoMigrationsExample.MigrationRuntimeTest.table_query(), [])
    actual = migrated.rows
    assert actual == [["posts"], ["users"]]
    actions = Ecto.Adapters.SQL.query!(repo, "SELECT confdeltype::text, confupdtype::text FROM pg_constraint WHERE conrelid = 'posts'::regclass AND contype = 'f'", [])
    actual = actions.rows
    assert actual == [["c", "c"]]
    Ecto.Adapters.SQL.query!(repo, "INSERT INTO users (id, name, email, inserted_at, updated_at) VALUES (101, 'QA', 'qa@example.invalid', NOW(), NOW())", [])
    Ecto.Adapters.SQL.query!(repo, "INSERT INTO posts (title, user_id, inserted_at, updated_at) VALUES ('QA post', 101, NOW(), NOW())", [])
    Ecto.Adapters.SQL.query!(repo, "UPDATE users SET id = 102 WHERE id = 101", [])
    actual = Ecto.Adapters.SQL.query!(repo, "SELECT user_id::text FROM posts", []).rows
    assert actual == [["102"]]
    Ecto.Adapters.SQL.query!(repo, "DELETE FROM users WHERE id = 102", [])
    actual = Ecto.Adapters.SQL.query!(repo, "SELECT count(*)::text FROM posts", []).rows
    assert actual == [["0"]]
    Ecto.Adapters.SQL.query!(repo, "DO $$ BEGIN BEGIN INSERT INTO posts (title, view_count, inserted_at, updated_at) VALUES ('invalid', -1, NOW(), NOW()); RAISE EXCEPTION 'negative count was accepted'; EXCEPTION WHEN check_violation THEN NULL; END; END $$", [])
    migration_path = System.fetch_env!("ECTO_MIGRATIONS_PATH")
    options = [{:all, true}]
    Ecto.Migrator.run(repo, migration_path, :down, options)
    rolled_back = Ecto.Adapters.SQL.query!(repo, EctoMigrationsExample.MigrationRuntimeTest.table_query(), [])
    actual = length(rolled_back.rows)
    assert actual == 0
  end
end
