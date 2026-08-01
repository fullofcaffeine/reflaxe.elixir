migrations_path = System.fetch_env!("ECTO_MIGRATIONS_PATH")
migration_files = Path.wildcard(Path.join(migrations_path, "*.exs"))

if migration_files == [] do
  raise "no migrations found under #{migrations_path}"
end

{_compiled, diagnostics} =
  Code.with_diagnostics(fn ->
    Enum.each(migration_files, &Code.compile_file/1)
  end)

warnings = Enum.filter(diagnostics, &(&1.severity == :warning))

if warnings != [] do
  Enum.each(warnings, fn diagnostic ->
    IO.puts(:stderr, "#{diagnostic.file}:#{inspect(diagnostic.position)}")
    IO.puts(:stderr, "warning: #{diagnostic.message}")
  end)

  System.halt(1)
end
