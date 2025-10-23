ExUnit.start()

# Explicitly require all compiled Haxe test modules under test/generated/**.ex
# This bridges Haxe-compiled .ex files into ExUnit's runtime without
# relying on *_test.exs filenames for discovery and avoids picking up
# non-test Elixir files or app redefinitions under test/.
for file <- Path.wildcard("test/generated/**/*.ex") do
  Code.require_file(file)
end
