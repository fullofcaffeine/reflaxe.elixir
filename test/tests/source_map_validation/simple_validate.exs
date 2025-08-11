#!/usr/bin/env elixir

# Simplified Source Map Validation
# Just checks basic structure without JSON parsing

defmodule SimpleValidator do
  def validate(path) do
    case File.read(path) do
      {:ok, content} ->
        # Basic structure checks without parsing
        checks = [
          {"Has version field", String.contains?(content, "\"version\"")},
          {"Version is 3", String.contains?(content, "\"version\": 3")},
          {"Has file field", String.contains?(content, "\"file\"")},
          {"Has sources array", String.contains?(content, "\"sources\"")},
          {"Has mappings field", String.contains?(content, "\"mappings\"")},
          {"Sources reference .hx files", String.contains?(content, ".hx")},
          {"Mappings not empty", not String.contains?(content, "\"mappings\": \"\"")},
          {"Valid JSON start", String.starts_with?(String.trim(content), "{")},
          {"Valid JSON end", String.ends_with?(String.trim(content), "}")}
        ]
        
        failed = checks
        |> Enum.reject(fn {_, result} -> result end)
        |> Enum.map(fn {check, _} -> check end)
        
        if Enum.empty?(failed) do
          :ok
        else
          {:error, failed}
        end
        
      {:error, reason} ->
        {:error, ["Cannot read file: #{inspect(reason)}"]}
    end
  end
end

IO.puts("=== Simple Source Map Validation ===\n")

out_dir = Path.join(__DIR__, "out")
map_files = Path.wildcard(Path.join(out_dir, "*.ex.map"))

if Enum.empty?(map_files) do
  IO.puts("❌ No source map files found")
  System.halt(1)
end

IO.puts("Validating #{length(map_files)} source map files...\n")

results = map_files
|> Enum.map(fn path ->
  name = Path.basename(path)
  result = SimpleValidator.validate(path)
  {name, result}
end)

{passed, failed} = Enum.split_with(results, fn {_, r} -> r == :ok end)

IO.puts("✅ Valid: #{length(passed)} files")
IO.puts("❌ Invalid: #{length(failed)} files")

if length(failed) > 0 do
  IO.puts("\nFailed validations:")
  Enum.each(failed, fn {file, {:error, checks}} ->
    IO.puts("  #{file}:")
    Enum.each(checks, fn check ->
      IO.puts("    - Failed: #{check}")
    end)
  end)
end

# Check main test file specifically
main_file = Path.join(out_dir, "SourceMapValidationTest.ex.map")
{:ok, content} = File.read(main_file)

IO.puts("\n=== Main Test File Analysis ===")
IO.puts("File: SourceMapValidationTest.ex.map")

# Extract key info with regex
case Regex.run(~r/"sources":\s*\[(.*?)\]/, content) do
  [_, sources] -> IO.puts("Sources: [#{sources}]")
  _ -> IO.puts("Sources: (not found)")
end

case Regex.run(~r/"version":\s*(\d+)/, content) do
  [_, version] -> IO.puts("Version: #{version}")
  _ -> IO.puts("Version: (not found)")
end

mappings = case Regex.run(~r/"mappings":\s*"([^"]*)"/, content) do
  [_, m] -> m
  _ -> ""
end

IO.puts("Mappings length: #{String.length(mappings)} characters")
IO.puts("Mappings sample: #{String.slice(mappings, 0, 50)}...")

# Count VLQ segments (separated by commas)
segments = String.split(mappings, ",")
IO.puts("Mapping segments: #{length(segments)}")

# Validation summary
if length(failed) == 0 do
  IO.puts("\n🎉 All source maps have valid structure!")
  System.halt(0)
else
  IO.puts("\n⚠️ Some source maps have issues")
  System.halt(1)
end