ExUnit.start()

{:ok, _pid} = EctoMigrationsExample.Repo.start_link()

for file <- Path.wildcard("test/generated/**/*_test.exs") do
  Code.require_file(file)
end
