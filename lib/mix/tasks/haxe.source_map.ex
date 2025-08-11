defmodule Mix.Tasks.Haxe.SourceMap do
  @moduledoc """
  Performs reverse source mapping lookups from generated Elixir positions 
  back to original Haxe source positions.
  
  This task is specifically designed for LLM agents that need to understand
  the relationship between generated Elixir code and original Haxe source,
  enabling accurate debugging at the correct abstraction level.
  
  ## Usage
  
      mix haxe.source_map FILE LINE COLUMN
      mix haxe.source_map --list-maps
      mix haxe.source_map --validate-maps
      mix haxe.source_map FILE LINE COLUMN --format json
      mix haxe.source_map FILE LINE COLUMN --with-context
  
  ## Arguments
  
    * `FILE` - Generated Elixir file path or original Haxe file path
    * `LINE` - Line number in the file (1-based)
    * `COLUMN` - Column number in the file (0-based)
  
  ## Options
  
    * `--format FORMAT` - Output format: table, json, detailed (default: detailed)
    * `--with-context` - Include source code context around the mapped position
    * `--list-maps` - List all available source map files
    * `--validate-maps` - Validate all source map files for correctness
    * `--reverse` - Perform reverse lookup (Haxe to Elixir)
    * `--target-dir DIR` - Directory to search for source maps (default: lib)
  
  ## Examples
  
      # Find Haxe source for Elixir position
      mix haxe.source_map lib/UserService.ex 25 10
      
      # Reverse lookup: find Elixir position for Haxe source
      mix haxe.source_map src/UserService.hx 15 5 --reverse
      
      # JSON output for LLM agents
      mix haxe.source_map lib/UserService.ex 25 10 --format json
      
      # With source code context
      mix haxe.source_map lib/UserService.ex 25 10 --with-context
      
      # List all available source maps
      mix haxe.source_map --list-maps
  
  ## LLM Agent Usage
  
  LLM agents should use this task when:
  
  1. **Error Analysis**: Map error positions from Elixir back to Haxe source
  2. **Code Navigation**: Understand the relationship between generated and source code
  3. **Debugging Strategy**: Determine whether to debug at Haxe or Elixir level
  4. **Cross-Reference Validation**: Verify that source mapping is accurate
  
  The JSON format output is optimized for programmatic consumption by LLM agents.
  """
  
  use Mix.Task
  
  @shortdoc "Perform reverse source mapping lookups between Haxe and Elixir"
  
  @switches [
    format: :string,
    with_context: :boolean,
    list_maps: :boolean,
    validate_maps: :boolean,
    reverse: :boolean,
    target_dir: :string,
    help: :boolean
  ]
  
  @aliases [
    f: :format,
    c: :with_context,
    l: :list_maps,
    v: :validate_maps,
    r: :reverse,
    t: :target_dir,
    h: :help
  ]
  
  def run([]), do: show_usage()
  def run(["--help"]), do: show_help()
  
  def run(args) do
    {opts, remaining_args} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)
    
    cond do
      opts[:help] ->
        show_help()
        
      opts[:list_maps] ->
        list_source_maps(opts)
        
      opts[:validate_maps] ->
        validate_source_maps(opts)
        
      length(remaining_args) >= 3 ->
        [file, line_str, column_str | _] = remaining_args
        
        case {Integer.parse(line_str), Integer.parse(column_str)} do
          {{line, ""}, {column, ""}} ->
            perform_lookup(file, line, column, opts)
            
          _ ->
            Mix.shell().error("Invalid line or column number")
            show_usage()
        end
        
      true ->
        show_usage()
    end
  end
  
  defp perform_lookup(file, line, column, opts) do
    target_dir = opts[:target_dir] || "lib"
    format = opts[:format] || "detailed"
    reverse = opts[:reverse] || false
    
    case find_and_parse_source_map(file, target_dir, reverse) do
      {:ok, {source_map, lookup_direction}} ->
        result = case lookup_direction do
          :elixir_to_haxe ->
            SourceMapLookup.lookup_haxe_position(source_map, line, column)
            
          :haxe_to_elixir ->
            # For reverse lookup, we need to search through all mappings
            find_elixir_position_for_haxe(source_map, file, line, column)
        end
        
        case result do
          {:ok, mapped_position} ->
            display_lookup_result(file, line, column, mapped_position, source_map, opts, lookup_direction, format)
            
          {:error, reason} ->
            Mix.shell().error("Lookup failed: #{reason}")
            suggest_alternatives(file, line, column, opts)
        end
        
      {:error, reason} ->
        Mix.shell().error("Source map error: #{reason}")
        suggest_alternatives(file, line, column, opts)
    end
  end
  
  defp find_and_parse_source_map(file, target_dir, reverse) do
    if reverse do
      # Reverse lookup: Haxe file to Elixir
      elixir_file = String.replace(file, ".hx", ".ex")
      source_map_path = Path.join(target_dir, Path.basename(elixir_file) <> ".map")
      
      case SourceMapLookup.parse_source_map(source_map_path) do
        {:ok, source_map} -> {:ok, {source_map, :haxe_to_elixir}}
        {:error, reason} -> {:error, reason}
      end
    else
      # Forward lookup: Elixir file to Haxe
      source_map_path = case Path.extname(file) do
        ".ex" ->
          file <> ".map"
          
        ".hx" ->
          # User provided Haxe file, find corresponding Elixir map
          elixir_file = String.replace(file, ".hx", ".ex")
          elixir_file <> ".map"
          
        _ ->
          file <> ".map"
      end
      
      case SourceMapLookup.parse_source_map(source_map_path) do
        {:ok, source_map} -> {:ok, {source_map, :elixir_to_haxe}}
        {:error, reason} -> {:error, reason}
      end
    end
  end
  
  defp find_elixir_position_for_haxe(source_map, haxe_file, haxe_line, haxe_column) do
    # Search through all mappings to find one that matches the Haxe position
    matching_mapping = Enum.find(source_map.mappings, fn mapping ->
      mapping.source_file == haxe_file and 
      mapping.source_line == (haxe_line - 1) and  # Convert to 0-based
      mapping.source_column == haxe_column
    end)
    
    case matching_mapping do
      nil ->
        # Try to find the closest mapping
        closest_mapping = Enum.min_by(source_map.mappings, fn mapping ->
          if mapping.source_file == haxe_file do
            abs((mapping.source_line + 1) - haxe_line) + abs(mapping.source_column - haxe_column)
          else
            999999  # Large number for non-matching files
          end
        end, fn -> nil end)
        
        case closest_mapping do
          nil ->
            {:error, "No mapping found for Haxe position #{haxe_file}:#{haxe_line}:#{haxe_column}"}
            
          mapping ->
            {:ok, %{
              file: source_map.file,
              line: mapping.generated_line + 1,  # Convert back to 1-based
              column: mapping.generated_column,
              approximate: true,
              original_position: %{
                line: haxe_line,
                column: haxe_column
              }
            }}
        end
        
      mapping ->
        {:ok, %{
          file: source_map.file,
          line: mapping.generated_line + 1,  # Convert back to 1-based
          column: mapping.generated_column,
          approximate: false,
          original_position: %{
            line: haxe_line,
            column: haxe_column
          }
        }}
    end
  end
  
  defp display_lookup_result(input_file, input_line, input_column, mapped_position, source_map, opts, direction, format) do
    case format do
      "json" ->
        display_json_result(input_file, input_line, input_column, mapped_position, source_map, direction)
        
      "table" ->
        display_table_result(input_file, input_line, input_column, mapped_position, source_map, opts, direction)
        
      "detailed" ->
        display_detailed_result(input_file, input_line, input_column, mapped_position, source_map, opts, direction)
        
      other ->
        Mix.shell().error("Unknown format: #{other}")
        Mix.shell().error("Available formats: json, table, detailed")
    end
  end
  
  defp display_json_result(input_file, input_line, input_column, mapped_position, source_map, direction) do
    result = %{
      lookup: %{
        input: %{
          file: input_file,
          line: input_line,
          column: input_column
        },
        output: mapped_position,
        direction: direction,
        accurate: !Map.get(mapped_position, :approximate, false)
      },
      source_map: %{
        file: source_map.source_map_path,
        version: source_map.version,
        generated_file: source_map.file,
        source_files: source_map.sources
      }
    }
    
    case Jason.encode(result, pretty: true) do
      {:ok, json} ->
        IO.puts(json)
        
      {:error, reason} ->
        Mix.shell().error("Failed to encode result as JSON: #{inspect(reason)}")
    end
  end
  
  defp display_detailed_result(input_file, input_line, input_column, mapped_position, source_map, opts, direction) do
    Mix.shell().info("🗺️  Source Mapping Lookup Result")
    Mix.shell().info("=" |> String.duplicate(50))
    Mix.shell().info("")
    
    {input_label, output_label} = case direction do
      :elixir_to_haxe -> {"Generated Elixir", "Original Haxe"}
      :haxe_to_elixir -> {"Original Haxe", "Generated Elixir"}
    end
    
    Mix.shell().info("📍 #{input_label} Position:")
    Mix.shell().info("   File: #{input_file}")
    Mix.shell().info("   Line: #{input_line}")
    Mix.shell().info("   Column: #{input_column}")
    Mix.shell().info("")
    
    Mix.shell().info("🎯 #{output_label} Position:")
    Mix.shell().info("   File: #{mapped_position.file}")
    Mix.shell().info("   Line: #{mapped_position.line}")
    Mix.shell().info("   Column: #{mapped_position.column}")
    
    if Map.get(mapped_position, :approximate, false) do
      Mix.shell().info("   ⚠️  Approximate match (closest available mapping)")
    else
      Mix.shell().info("   ✅ Exact match")
    end
    
    Mix.shell().info("")
    Mix.shell().info("🗂️  Source Map Information:")
    Mix.shell().info("   Source Map: #{Path.basename(source_map.source_map_path)}")
    Mix.shell().info("   Generated File: #{source_map.file}")
    Mix.shell().info("   Source Files: #{Enum.join(source_map.sources, ", ")}")
    Mix.shell().info("")
    
    if opts[:with_context] do
      display_position_context(mapped_position.file, mapped_position.line)
    end
    
    display_debug_recommendations(direction, input_file, mapped_position.file)
  end
  
  defp display_table_result(input_file, input_line, input_column, mapped_position, _source_map, _opts, direction) do
    Mix.shell().info("Source Mapping Lookup")
    Mix.shell().info("-" |> String.duplicate(30))
    
    {input_type, output_type} = case direction do
      :elixir_to_haxe -> {"Elixir", "Haxe"}
      :haxe_to_elixir -> {"Haxe", "Elixir"}
    end
    
    Mix.shell().info("#{input_type}: #{input_file}:#{input_line}:#{input_column}")
    Mix.shell().info("#{output_type}: #{mapped_position.file}:#{mapped_position.line}:#{mapped_position.column}")
    
    if Map.get(mapped_position, :approximate, false) do
      Mix.shell().info("Status: Approximate")
    else
      Mix.shell().info("Status: Exact")
    end
  end
  
  defp display_position_context(file_path, line_number) do
    Mix.shell().info("📄 Source Context:")
    
    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          lines = String.split(content, "\n")
          
          # Show 2 lines before and after
          start_line = max(1, line_number - 2)
          end_line = min(length(lines), line_number + 2)
          
          lines
          |> Enum.with_index(1)
          |> Enum.filter(fn {_line, index} -> 
            index >= start_line and index <= end_line
          end)
          |> Enum.each(fn {line, index} ->
            marker = if index == line_number, do: ">>> ", else: "    "
            formatted_line = "   #{String.pad_leading(Integer.to_string(index), 4)} #{marker}#{line}"
            Mix.shell().info(formatted_line)
          end)
          
        {:error, _} ->
          Mix.shell().info("   ❌ Failed to read source file")
      end
    else
      Mix.shell().info("   ❌ Source file not found")
    end
    
    Mix.shell().info("")
  end
  
  defp display_debug_recommendations(direction, _input_file, output_file) do
    Mix.shell().info("🤖 LLM Agent Debug Recommendations:")
    
    case direction do
      :elixir_to_haxe ->
        Mix.shell().info("   • Debug at HAXE level in #{output_file}")
        Mix.shell().info("   • Check Haxe source code for logical errors")
        Mix.shell().info("   • Verify type annotations and imports")
        Mix.shell().info("   • Use: mix haxe.inspect #{output_file}")
        
      :haxe_to_elixir ->
        Mix.shell().info("   • Verify generated Elixir in #{output_file}")
        Mix.shell().info("   • Check if Elixir compilation is successful")
        Mix.shell().info("   • Compare with expected Phoenix/Ecto patterns")
        Mix.shell().info("   • Use: mix compile --verbose")
    end
    
    Mix.shell().info("")
  end
  
  defp list_source_maps(opts) do
    target_dir = opts[:target_dir] || "lib"
    source_maps = SourceMapLookup.find_available_source_maps(target_dir)
    
    Mix.shell().info("🗺️  Available Source Maps in #{target_dir}:")
    Mix.shell().info("")
    
    if Enum.empty?(source_maps) do
      Mix.shell().info("   No source map files found")
      Mix.shell().info("   Make sure to compile with source mapping enabled:")
      Mix.shell().info("   haxe build.hxml -D source-map")
    else
      source_maps
      |> Enum.sort()
      |> Enum.each(fn source_map_path ->
        case SourceMapLookup.parse_source_map(source_map_path) do
          {:ok, source_map} ->
            Mix.shell().info("   ✅ #{Path.relative_to_cwd(source_map_path)}")
            Mix.shell().info("      → #{source_map.file} (#{Enum.count(source_map.sources)} source files)")
            
          {:error, _} ->
            Mix.shell().info("   ❌ #{Path.relative_to_cwd(source_map_path)} (invalid)")
        end
      end)
      
      Mix.shell().info("")
      Mix.shell().info("Found #{length(source_maps)} source map files")
    end
  end
  
  defp validate_source_maps(opts) do
    target_dir = opts[:target_dir] || "lib"
    source_maps = SourceMapLookup.find_available_source_maps(target_dir)
    
    Mix.shell().info("🔍 Validating Source Maps in #{target_dir}:")
    Mix.shell().info("")
    
    if Enum.empty?(source_maps) do
      Mix.shell().info("   No source map files found")
    else
      {valid_count, invalid_count} = 
        source_maps
        |> Enum.map(fn source_map_path ->
          case SourceMapLookup.parse_source_map(source_map_path) do
            {:ok, source_map} ->
              # Additional validation checks
              checks = [
                {length(source_map.sources) > 0, "Has source files"},
                {length(source_map.mappings) > 0, "Has position mappings"},
                {File.exists?(source_map.file), "Generated file exists"}
              ]
              
              all_valid = Enum.all?(checks, fn {valid, _} -> valid end)
              
              status = if all_valid, do: "✅", else: "⚠️ "
              Mix.shell().info("   #{status} #{Path.relative_to_cwd(source_map_path)}")
              
              Enum.each(checks, fn {valid, description} ->
                check_status = if valid, do: "✓", else: "✗"
                Mix.shell().info("      #{check_status} #{description}")
              end)
              
              if all_valid, do: :valid, else: :invalid
              
            {:error, reason} ->
              Mix.shell().info("   ❌ #{Path.relative_to_cwd(source_map_path)}")
              Mix.shell().info("      Error: #{reason}")
              :invalid
          end
        end)
        |> Enum.reduce({0, 0}, fn result, {valid, invalid} ->
          case result do
            :valid -> {valid + 1, invalid}
            :invalid -> {valid, invalid + 1}
          end
        end)
      
      Mix.shell().info("")
      Mix.shell().info("Validation Summary: #{valid_count} valid, #{invalid_count} invalid")
    end
  end
  
  defp suggest_alternatives(file, line, column, _opts) do
    Mix.shell().info("")
    Mix.shell().info("💡 Suggestions:")
    Mix.shell().info("   • Check if source maps are generated: mix haxe.source_map --list-maps")
    Mix.shell().info("   • Compile with source mapping: haxe build.hxml -D source-map")
    Mix.shell().info("   • Verify file path is correct: #{file}")
    Mix.shell().info("   • Try approximate position nearby: #{line}±2:#{column}±5")
  end
  
  defp show_usage do
    Mix.shell().info("Usage: mix haxe.source_map FILE LINE COLUMN [options]")
    Mix.shell().info("       mix haxe.source_map --list-maps")
    Mix.shell().info("       mix haxe.source_map --validate-maps")
    Mix.shell().info("")
    Mix.shell().info("For help: mix haxe.source_map --help")
  end
  
  defp show_help do
    Mix.shell().info("mix haxe.source_map - Reverse source mapping lookups")
    Mix.shell().info("")
    Mix.shell().info("Usage:")
    Mix.shell().info("  mix haxe.source_map FILE LINE COLUMN [options]")
    Mix.shell().info("  mix haxe.source_map --list-maps")
    Mix.shell().info("  mix haxe.source_map --validate-maps")
    Mix.shell().info("")
    Mix.shell().info("Arguments:")
    Mix.shell().info("  FILE        Generated Elixir file or original Haxe file")
    Mix.shell().info("  LINE        Line number (1-based)")
    Mix.shell().info("  COLUMN      Column number (0-based)")
    Mix.shell().info("")
    Mix.shell().info("Options:")
    Mix.shell().info("  --format FORMAT     Output format: json, table, detailed (default: detailed)")
    Mix.shell().info("  --with-context      Include source code context")
    Mix.shell().info("  --list-maps         List all available source map files")
    Mix.shell().info("  --validate-maps     Validate all source map files")
    Mix.shell().info("  --reverse           Perform reverse lookup (Haxe to Elixir)")
    Mix.shell().info("  --target-dir DIR    Directory to search for source maps (default: lib)")
    Mix.shell().info("  --help              Show this help")
    Mix.shell().info("")
    Mix.shell().info("Examples:")
    Mix.shell().info("  mix haxe.source_map lib/UserService.ex 25 10")
    Mix.shell().info("  mix haxe.source_map src/UserService.hx 15 5 --reverse")
    Mix.shell().info("  mix haxe.source_map lib/UserService.ex 25 10 --format json")
    Mix.shell().info("  mix haxe.source_map --list-maps")
  end
end