#!/usr/bin/env elixir

# Source Map Structure Validation Test
# Tests that generated source maps meet v3 specification requirements

defmodule SourceMapValidator do
  @required_fields ["version", "file", "sources", "mappings"]
  @valid_version 3
  
  def validate_source_map(path) do
    case File.read(path) do
      {:ok, content} ->
        case :json.decode(content, %{}) do
          {:ok, map} ->
            validate_structure(map, path)
          {:error, reason} ->
            {:error, "Invalid JSON: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Cannot read file: #{inspect(reason)}"}
    end
  end
  
  defp validate_structure(map, path) do
    errors = []
    
    # Check required fields
    errors = errors ++ check_required_fields(map)
    
    # Check version
    errors = errors ++ check_version(map)
    
    # Check sources array
    errors = errors ++ check_sources(map, path)
    
    # Check mappings
    errors = errors ++ check_mappings(map)
    
    # Check file reference
    errors = errors ++ check_file_reference(map, path)
    
    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end
  
  defp check_required_fields(map) do
    @required_fields
    |> Enum.reject(&Map.has_key?(map, &1))
    |> Enum.map(&"Missing required field: #{&1}")
  end
  
  defp check_version(map) do
    case Map.get(map, "version") do
      @valid_version -> []
      version -> ["Invalid version: #{inspect(version)}, expected #{@valid_version}"]
    end
  end
  
  defp check_sources(map, path) do
    sources = Map.get(map, "sources", [])
    
    cond do
      !is_list(sources) ->
        ["Sources must be an array"]
      
      Enum.empty?(sources) ->
        ["Sources array is empty"]
      
      true ->
        # Check that sources reference .hx files
        invalid_sources = sources
        |> Enum.reject(&String.ends_with?(&1, ".hx"))
        |> Enum.map(&"Invalid source extension: #{&1} (expected .hx)")
        
        # Check that the source file name matches the map file base name
        base_name = path
        |> Path.basename()
        |> String.replace(".ex.map", "")
        
        expected_source = "#{base_name}.hx"
        
        if expected_source in sources do
          invalid_sources
        else
          ["Expected source #{expected_source} not found in sources"] ++ invalid_sources
        end
    end
  end
  
  defp check_mappings(map) do
    mappings = Map.get(map, "mappings", "")
    
    cond do
      !is_binary(mappings) ->
        ["Mappings must be a string"]
      
      mappings == "" ->
        ["Mappings string is empty"]
      
      true ->
        # Basic VLQ validation - check for valid Base64 VLQ characters
        valid_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/,;"
        invalid_chars = mappings
        |> String.graphemes()
        |> Enum.reject(&String.contains?(valid_chars, &1))
        |> Enum.uniq()
        
        if Enum.empty?(invalid_chars) do
          []
        else
          ["Invalid VLQ characters in mappings: #{inspect(invalid_chars)}"]
        end
    end
  end
  
  defp check_file_reference(map, path) do
    file = Map.get(map, "file")
    expected_file = path
    |> Path.basename()
    |> String.replace(".map", "")
    
    if file == expected_file do
      []
    else
      ["File reference mismatch: expected #{expected_file}, got #{inspect(file)}"]
    end
  end
end

# Main execution
IO.puts("=== Source Map Validation Test ===\n")

out_dir = Path.join(__DIR__, "out")
map_files = Path.wildcard(Path.join(out_dir, "*.ex.map"))

if Enum.empty?(map_files) do
  IO.puts("❌ No source map files found in #{out_dir}")
  System.halt(1)
else
  IO.puts("Found #{length(map_files)} source map files to validate\n")
  
  results = map_files
  |> Enum.map(fn path ->
    file_name = Path.basename(path)
    result = SourceMapValidator.validate_source_map(path)
    {file_name, result}
  end)
  
  # Display results
  {passed, failed} = Enum.split_with(results, fn {_, result} -> result == :ok end)
  
  IO.puts("✅ Passed: #{length(passed)} files")
  if length(passed) > 0 do
    passed
    |> Enum.take(5)
    |> Enum.each(fn {file, _} -> IO.puts("   • #{file}") end)
    
    if length(passed) > 5 do
      IO.puts("   ... and #{length(passed) - 5} more")
    end
  end
  
  if length(failed) > 0 do
    IO.puts("\n❌ Failed: #{length(failed)} files")
    Enum.each(failed, fn {file, {:error, errors}} ->
      IO.puts("   • #{file}:")
      Enum.each(errors, fn error ->
        IO.puts("     - #{error}")
      end)
    end)
  end
  
  IO.puts("\n=== Summary ===")
  IO.puts("Total: #{length(map_files)} files")
  IO.puts("Passed: #{length(passed)} (#{round(length(passed) / length(map_files) * 100)}%)")
  IO.puts("Failed: #{length(failed)} (#{round(length(failed) / length(map_files) * 100)}%)")
  
  # Check specific important file
  main_file = "SourceMapValidationTest.ex.map"
  main_result = results |> Enum.find(fn {file, _} -> file == main_file end)
  
  case main_result do
    {_, :ok} ->
      IO.puts("\n✅ Main test file #{main_file} passed all validations!")
      
      # Show sample of its content
      main_path = Path.join(out_dir, main_file)
      {:ok, content} = File.read(main_path)
      {:ok, map} = :json.decode(content, %{})
      
      IO.puts("\nSource Map Statistics:")
      IO.puts("  • Version: #{map["version"]}")
      IO.puts("  • Sources: #{inspect(map["sources"])}")
      IO.puts("  • Mappings length: #{String.length(map["mappings"])} characters")
      IO.puts("  • Names: #{length(Map.get(map, "names", []))} entries")
      
    _ ->
      IO.puts("\n❌ Main test file #{main_file} failed validation!")
  end
  
  # Exit with appropriate code
  if length(failed) == 0 do
    IO.puts("\n🎉 All source maps valid!")
    System.halt(0)
  else
    System.halt(1)
  end
end