ExUnit.start()

# Explicitly require all compiled Haxe test modules under test/**.ex
# This bridges Haxe-compiled .ex files into ExUnit's runtime without
# relying on *_test.exs filenames for discovery.
for file <- Path.wildcard("test/**/*.ex") do
  Code.require_file(file)
end

