ExUnit.start()

for file <- Path.wildcard("test/generated/**/*_test.exs") do
  Code.require_file(file)
end
