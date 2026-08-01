alias EctoMigrationsExample.Repo

marker_path = System.fetch_env!("ECTO_MIGRATIONS_OWNERSHIP_MARKER")
database_name = System.fetch_env!("ECTO_MIGRATIONS_DATABASE")

case Repo.__adapter__().storage_up(Repo.config()) do
  :ok ->
    File.write!(marker_path, database_name <> "\n", [:exclusive])

  {:error, :already_up} ->
    raise "refusing to use existing QA database #{database_name}"

  {:error, reason} ->
    raise "could not create QA database #{database_name}: #{inspect(reason)}"
end
