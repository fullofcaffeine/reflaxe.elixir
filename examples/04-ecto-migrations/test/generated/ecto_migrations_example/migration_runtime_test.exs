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
    migration_path = System.fetch_env!("ECTO_MIGRATIONS_PATH")
    options = [{:all, true}]
    Ecto.Migrator.run(repo, migration_path, :down, options)
    rolled_back = Ecto.Adapters.SQL.query!(repo, EctoMigrationsExample.MigrationRuntimeTest.table_query(), [])
    actual = length(rolled_back.rows)
    assert actual == 0
  end
end
