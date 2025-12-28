defmodule Mix.Tasks.Haxe.Inspect do
  @moduledoc """
  Comprehensive cross-reference inspection tool for Haxe↔Elixir code analysis.
  
  This task provides deep inspection and cross-referencing capabilities between
  original Haxe source code and generated Elixir code, optimized for LLM agents
  that need to understand code generation patterns and debug at the correct
  abstraction level.
  
  ## Usage
  
      mix haxe.inspect FILE
      mix haxe.inspect FILE --with-mappings
      mix haxe.inspect FILE --compare
      mix haxe.inspect FILE --format json
      mix haxe.inspect FILE --json
      mix haxe.inspect --analyze-patterns
      mix haxe.inspect --list-files
  
  ## Arguments
  
    * `FILE` - Haxe source file (.hx) or generated Elixir file (.ex)
  
  ## Options
  
    * `--with-mappings` - Include detailed source mapping information
    * `--compare` - Side-by-side comparison of source and generated code
    * `--format FORMAT` - Output format: detailed, json, table (default: detailed)
    * `--analyze-patterns` - Analyze common Haxe→Elixir transformation patterns
    * `--list-files` - List all available Haxe/Elixir file pairs
    * `--show-annotations` - Show annotations and metadata transformations
    * `--context LINES` - Number of context lines to show (default: 3)
    * `--target-dir DIR` - Directory to search for files (default: current project)
  
  ## Examples
  
      # Inspect a Haxe file and its generated Elixir counterpart
      mix haxe.inspect src/UserService.hx
      
      # Inspect with source mapping details
      mix haxe.inspect src/UserService.hx --with-mappings
      
      # Side-by-side comparison
      mix haxe.inspect src/UserService.hx --compare
      
      # JSON output for LLM agents
      mix haxe.inspect src/UserService.hx --format json
      
      # Analyze transformation patterns across the project
      mix haxe.inspect --analyze-patterns
      
      # List all available Haxe/Elixir pairs
      mix haxe.inspect --list-files
  
  ## LLM Agent Usage
  
  This task is specifically designed for LLM agents to:
  
  1. **Understand Code Generation**: See how Haxe constructs map to Elixir patterns
  2. **Debug Strategy Selection**: Determine whether issues are in source or generation
  3. **Pattern Analysis**: Learn common transformation patterns for better assistance
  4. **Cross-Language Navigation**: Efficiently move between source and generated code
  5. **Annotation Understanding**: See how Haxe annotations affect Elixir generation
  
  The JSON output provides structured data optimized for programmatic consumption.
  """
  
  use Mix.Task
  
  @shortdoc "Comprehensive cross-reference inspection for Haxe↔Elixir code"
  
  @switches [
    with_mappings: :boolean,
    compare: :boolean,
    format: :string,
    json: :boolean,
    analyze_patterns: :boolean,
    list_files: :boolean,
    show_annotations: :boolean,
    context: :integer,
    target_dir: :string,
    help: :boolean
  ]
  
  @aliases [
    m: :with_mappings,
    c: :compare,
    f: :format,
    j: :json,
    a: :analyze_patterns,
    l: :list_files,
    s: :show_annotations,
    n: :context,
    t: :target_dir,
    h: :help
  ]
  
  def run([]), do: show_usage()
  def run(["--help"]), do: show_help()
  
  def run(args) do
    {opts, remaining_args} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)
    opts = normalize_opts(opts)
    
    cond do
      opts[:help] ->
        show_help()
        
      opts[:list_files] ->
        list_file_pairs(opts)
        
      opts[:analyze_patterns] ->
        analyze_transformation_patterns(opts)
        
      length(remaining_args) >= 1 ->
        [file | _] = remaining_args
        inspect_file(file, opts)
        
      true ->
        show_usage()
    end
  end

  defp normalize_opts(opts) do
    if Keyword.get(opts, :json, false), do: Keyword.put(opts, :format, "json"), else: opts
  end
  
  defp inspect_file(file, opts) do
    format = opts[:format] || "detailed"
    
    case find_file_pair(file, opts) do
      {:ok, {haxe_file, elixir_file, source_map_file}} ->
        inspection_data = build_inspection_data(haxe_file, elixir_file, source_map_file, opts)
        
        case format do
          "json" ->
            display_json_inspection(inspection_data)
            
          "table" ->
            display_table_inspection(inspection_data, opts)
            
          "detailed" ->
            display_detailed_inspection(inspection_data, opts)
            
          other ->
            Mix.shell().error("Unknown format: #{other}")
            Mix.shell().error("Available formats: json, table, detailed")
        end
        
      {:error, reason} ->
        Mix.shell().error("File inspection failed: #{reason}")
        suggest_file_alternatives(file, opts)
    end
  end
  
  defp find_file_pair(file, opts) do
    target_dir = opts[:target_dir] || get_project_directories()
    
    case Path.extname(file) do
      ".hx" ->
        # Haxe file provided - find corresponding Elixir file
        elixir_file = find_elixir_file_for_haxe(file, target_dir)
        source_map_file = elixir_file <> ".map"
        
        if File.exists?(file) and File.exists?(elixir_file) do
          {:ok, {file, elixir_file, source_map_file}}
        else
          {:error, "Corresponding Elixir file not found: #{elixir_file}"}
        end
        
      ".ex" ->
        # Elixir file provided - find corresponding Haxe file
        haxe_file = find_haxe_file_for_elixir(file, target_dir)
        source_map_file = file <> ".map"
        
        if File.exists?(file) and File.exists?(haxe_file) do
          {:ok, {haxe_file, file, source_map_file}}
        else
          {:error, "Corresponding Haxe file not found: #{haxe_file}"}
        end
        
      _ ->
        {:error, "File must be a Haxe (.hx) or Elixir (.ex) file"}
    end
  end
  
  defp build_inspection_data(haxe_file, elixir_file, source_map_file, opts) do
    haxe_content = read_file_safely(haxe_file)
    elixir_content = read_file_safely(elixir_file)
    source_map = parse_source_map_safely(source_map_file)
    
    %{
      files: %{
        haxe: %{
          path: haxe_file,
          content: haxe_content,
          exists: File.exists?(haxe_file),
          lines: if(haxe_content, do: String.split(haxe_content, "\\n"), else: [])
        },
        elixir: %{
          path: elixir_file,
          content: elixir_content,
          exists: File.exists?(elixir_file),
          lines: if(elixir_content, do: String.split(elixir_content, "\\n"), else: [])
        },
        source_map: %{
          path: source_map_file,
          data: source_map,
          exists: File.exists?(source_map_file)
        }
      },
      analysis: %{
        haxe_annotations: extract_haxe_annotations(haxe_content),
        elixir_patterns: extract_elixir_patterns(elixir_content),
        transformation_summary: analyze_transformation(haxe_content, elixir_content),
        source_mappings: if(source_map, do: get_mapping_summary(source_map), else: nil)
      },
      cross_reference: build_cross_reference_data(haxe_content, elixir_content, source_map, opts)
    }
  end
  
  defp display_detailed_inspection(data, opts) do
    Mix.shell().info("🔍 Haxe↔Elixir Cross-Reference Inspection")
    Mix.shell().info("=" |> String.duplicate(60))
    Mix.shell().info("")
    
    display_file_summary(data.files)
    display_transformation_analysis(data.analysis, opts)
    
    if opts[:with_mappings] && data.files.source_map.exists do
      display_source_mapping_details(data.files.source_map.data)
    end
    
    if opts[:compare] do
      display_side_by_side_comparison(data.files.haxe, data.files.elixir, opts)
    end
    
    if opts[:show_annotations] do
      display_annotation_analysis(data.analysis.haxe_annotations, data.analysis.elixir_patterns)
    end
    
    display_llm_recommendations(data)
  end
  
  defp display_json_inspection(data) do
    # Remove file content from JSON output to keep it manageable
    json_data = %{
      files: %{
        haxe: %{
          path: data.files.haxe.path,
          exists: data.files.haxe.exists,
          line_count: length(data.files.haxe.lines)
        },
        elixir: %{
          path: data.files.elixir.path,
          exists: data.files.elixir.exists,
          line_count: length(data.files.elixir.lines)
        },
        source_map: %{
          path: data.files.source_map.path,
          exists: data.files.source_map.exists
        }
      },
      analysis: data.analysis,
      cross_reference: data.cross_reference
    }
    
    if Code.ensure_loaded?(Jason) do
      case Jason.encode(json_data, pretty: true) do
        {:ok, json} ->
          IO.puts(json)
          
        {:error, reason} ->
          Mix.shell().error("Failed to encode inspection data as JSON: #{inspect(reason)}")
      end
    else
      Mix.shell().error("Jason library not available. Cannot output JSON format.")
      Mix.shell().info("Install Jason with: mix deps.get")
    end
  end
  
  defp display_table_inspection(data, _opts) do
    Mix.shell().info("File Inspection Summary")
    Mix.shell().info("-" |> String.duplicate(30))
    
    Mix.shell().info("Haxe: #{data.files.haxe.path} (#{length(data.files.haxe.lines)} lines)")
    Mix.shell().info("Elixir: #{data.files.elixir.path} (#{length(data.files.elixir.lines)} lines)")
    
    if data.files.source_map.exists do
      Mix.shell().info("Source Map: ✅ Available")
    else
      Mix.shell().info("Source Map: ❌ Not found")
    end
    
    Mix.shell().info("Annotations: #{length(data.analysis.haxe_annotations)}")
    Mix.shell().info("Transformation: #{data.analysis.transformation_summary.pattern}")
  end
  
  defp display_file_summary(files) do
    Mix.shell().info("📁 File Information:")
    Mix.shell().info("")
    
    haxe_status = if files.haxe.exists, do: "✅", else: "❌"
    elixir_status = if files.elixir.exists, do: "✅", else: "❌"
    map_status = if files.source_map.exists, do: "✅", else: "❌"
    
    Mix.shell().info("   #{haxe_status} Haxe Source: #{files.haxe.path} (#{length(files.haxe.lines)} lines)")
    Mix.shell().info("   #{elixir_status} Generated Elixir: #{files.elixir.path} (#{length(files.elixir.lines)} lines)")
    Mix.shell().info("   #{map_status} Source Map: #{files.source_map.path}")
    
    Mix.shell().info("")
  end
  
  defp display_transformation_analysis(analysis, _opts) do
    Mix.shell().info("🔄 Transformation Analysis:")
    Mix.shell().info("")
    
    Mix.shell().info("   Pattern: #{analysis.transformation_summary.pattern}")
    Mix.shell().info("   Complexity: #{analysis.transformation_summary.complexity}")
    Mix.shell().info("   Annotations Found: #{length(analysis.haxe_annotations)}")
    
    if length(analysis.haxe_annotations) > 0 do
      Mix.shell().info("   Key Annotations:")
      
      analysis.haxe_annotations
      |> Enum.take(5)
      |> Enum.each(fn annotation ->
        Mix.shell().info("     • #{annotation.name}: #{annotation.description}")
      end)
    end
    
    Mix.shell().info("")
  end
  
  defp display_source_mapping_details(source_map_data) do
    if source_map_data do
      Mix.shell().info("🗺️  Source Mapping Details:")
      Mix.shell().info("")
      Mix.shell().info("   Version: #{source_map_data.version}")
      Mix.shell().info("   Source Files: #{Enum.join(source_map_data.sources, ", ")}")
      Mix.shell().info("   Mappings: #{length(source_map_data.mappings)} position mappings")
      Mix.shell().info("")
    end
  end
  
  defp display_side_by_side_comparison(haxe_file, elixir_file, _opts) do
    # context_lines = opts[:context] || 3  # Reserved for future use
    
    Mix.shell().info("🔀 Side-by-Side Comparison:")
    Mix.shell().info("")
    
    max_lines = max(length(haxe_file.lines), length(elixir_file.lines))
    
    # Show first few lines for demonstration
    comparison_lines = min(max_lines, 10)
    
    Mix.shell().info("   #{String.pad_trailing("Haxe Source", 40)} | Elixir Generated")
    Mix.shell().info("   " <> String.duplicate("-", 40) <> " | " <> String.duplicate("-", 40))
    
    for i <- 1..comparison_lines do
      haxe_line = Enum.at(haxe_file.lines, i - 1, "")
      elixir_line = Enum.at(elixir_file.lines, i - 1, "")
      
      haxe_truncated = String.slice(haxe_line, 0, 38)
      elixir_truncated = String.slice(elixir_line, 0, 38)
      
      Mix.shell().info("   #{String.pad_trailing(haxe_truncated, 40)} | #{elixir_truncated}")
    end
    
    if max_lines > 10 do
      Mix.shell().info("   ... (#{max_lines - 10} more lines) ...")
    end
    
    Mix.shell().info("")
  end
  
  defp display_annotation_analysis(haxe_annotations, elixir_patterns) do
    Mix.shell().info("📋 Annotation → Pattern Analysis:")
    Mix.shell().info("")
    
    if length(haxe_annotations) == 0 do
      Mix.shell().info("   No annotations found in Haxe source")
    else
      Mix.shell().info("   Haxe Annotations:")
      Enum.each(haxe_annotations, fn annotation ->
        Mix.shell().info("     • @#{annotation.name}: #{annotation.description}")
      end)
    end
    
    if length(elixir_patterns) == 0 do
      Mix.shell().info("   No special patterns detected in generated Elixir")
    else
      Mix.shell().info("   Generated Elixir Patterns:")
      Enum.each(elixir_patterns, fn pattern ->
        Mix.shell().info("     • #{pattern.type}: #{pattern.description}")
      end)
    end
    
    Mix.shell().info("")
  end
  
  defp display_llm_recommendations(data) do
    Mix.shell().info("🤖 LLM Agent Recommendations:")
    Mix.shell().info("")
    
    recommendations = build_llm_recommendations(data)
    
    Mix.shell().info("   Primary Focus: #{recommendations.primary_focus}")
    Mix.shell().info("   Debug Level: #{recommendations.debug_level}")
    
    Mix.shell().info("   Suggested Actions:")
    recommendations.actions
    |> Enum.with_index(1)
    |> Enum.each(fn {action, index} ->
      Mix.shell().info("     #{index}. #{action}")
    end)
    
    if recommendations.related_commands do
      Mix.shell().info("")
      Mix.shell().info("   Related Commands:")
      Enum.each(recommendations.related_commands, fn cmd ->
        Mix.shell().info("     • #{cmd}")
      end)
    end
    
    Mix.shell().info("")
  end
  
  defp list_file_pairs(opts) do
    target_dir = opts[:target_dir] || get_project_directories()
    pairs = find_all_haxe_elixir_pairs(target_dir)

    format = opts[:format] || "detailed"
    if format == "json" do
      list_file_pairs_json(pairs)
    else
      list_file_pairs_human(pairs)
    end
  end

  defp list_file_pairs_json(pairs) do
    output = %{
      pairs:
        Enum.map(pairs, fn {haxe_file, elixir_file, source_map_file} ->
          %{
            haxe_file: Path.relative_to_cwd(haxe_file),
            elixir_file: Path.relative_to_cwd(elixir_file),
            source_map_file: Path.relative_to_cwd(source_map_file),
            has_source_map: File.exists?(source_map_file)
          }
        end),
      total: length(pairs)
    }

    emit_json(output)
  end

  defp list_file_pairs_human(pairs) do
    
    Mix.shell().info("📂 Available Haxe↔Elixir File Pairs:")
    Mix.shell().info("")
    
    if Enum.empty?(pairs) do
      Mix.shell().info("   No Haxe/Elixir pairs found")
      Mix.shell().info("   Make sure files are compiled and present in the target directories")
    else
      pairs
      |> Enum.sort_by(fn {haxe, _elixir, _map} -> haxe end)
      |> Enum.each(fn {haxe_file, elixir_file, source_map_file} ->
        map_status = if File.exists?(source_map_file), do: "🗺️", else: "  "
        Mix.shell().info("   #{map_status} #{Path.relative_to_cwd(haxe_file)}")
        Mix.shell().info("       → #{Path.relative_to_cwd(elixir_file)}")
      end)
      
      Mix.shell().info("")
      Mix.shell().info("Found #{length(pairs)} Haxe↔Elixir pairs")
      
      with_maps = Enum.count(pairs, fn {_, _, map} -> File.exists?(map) end)
      Mix.shell().info("#{with_maps} pairs have source maps (🗺️)")
    end
  end
  
  defp analyze_transformation_patterns(opts) do
    format = opts[:format] || "detailed"

    patterns = [
      %{
        name: "Class → Module",
        frequency: "Very Common",
        description: "Haxe classes become Elixir defmodule declarations"
      },
      %{
        name: "@:liveview → Phoenix.LiveView",
        frequency: "Common",
        description: "LiveView annotation generates Phoenix LiveView modules"
      },
      %{
        name: "@:schema → Ecto.Schema",
        frequency: "Common",
        description: "Schema annotation generates Ecto schema modules"
      },
      %{
        name: "Static Functions → def",
        frequency: "Very Common",
        description: "Static Haxe functions become public Elixir functions"
      },
      %{
        name: "Instance Functions → def with context",
        frequency: "Common",
        description: "Instance functions receive implicit context parameter"
      }
    ]

    if format == "json" do
      emit_json(%{patterns: patterns, total: length(patterns)})
    else
      analyze_transformation_patterns_human(patterns)
    end
  end

  defp analyze_transformation_patterns_human(patterns) do
    Mix.shell().info("🔬 Haxe→Elixir Transformation Pattern Analysis")
    Mix.shell().info("=" |> String.duplicate(60))
    Mix.shell().info("")
    
    Mix.shell().info("Common Transformation Patterns:")
    Mix.shell().info("")
    
    patterns
    |> Enum.with_index(1)
    |> Enum.each(fn {pattern, index} ->
      Mix.shell().info("#{index}. #{pattern.name} (#{pattern.frequency})")
      Mix.shell().info("   #{pattern.description}")
      Mix.shell().info("")
    end)
    
    Mix.shell().info("💡 Pattern Understanding Benefits:")
    Mix.shell().info("   • Faster debugging by understanding common transformations")
    Mix.shell().info("   • Better prediction of generated code structure")
    Mix.shell().info("   • Improved error analysis and resolution strategies")
    Mix.shell().info("")
  end

  defp emit_json(payload) do
    if Code.ensure_loaded?(Jason) do
      case Jason.encode(payload, pretty: true) do
        {:ok, json} -> IO.puts(json)
        {:error, reason} -> Mix.shell().error("Failed to encode JSON: #{inspect(reason)}")
      end
    else
      Mix.shell().error("Jason library not available. Cannot output JSON format.")
      Mix.shell().info("Install Jason with: mix deps.get")
    end
  end
  
  # Helper functions
  
  defp read_file_safely(file_path) do
    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} -> content
        {:error, _} -> nil
      end
    else
      nil
    end
  end
  
  defp parse_source_map_safely(source_map_path) do
    if File.exists?(source_map_path) do
      case SourceMapLookup.parse_source_map(source_map_path) do
        {:ok, source_map} -> source_map
        {:error, _} -> nil
      end
    else
      nil
    end
  end
  
  defp extract_haxe_annotations(content) do
    if content do
      # Simple annotation extraction - in production, this would be more sophisticated
      content
      |> String.split("\\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_num} ->
        case Regex.scan(~r/@:(\w+)(?:\((.*?)\))?/, line) do
          [] -> []
          matches ->
            Enum.map(matches, fn
              [_, annotation] ->
                %{
                  name: annotation,
                  line: line_num,
                  description: describe_annotation(annotation),
                  parameters: nil
                }
              [_, annotation, params] ->
                %{
                  name: annotation,
                  line: line_num,
                  description: describe_annotation(annotation),
                  parameters: params
                }
            end)
        end
      end)
    else
      []
    end
  end
  
  defp extract_elixir_patterns(content) do
    if content do
      patterns = []
      
      # Check for common Elixir patterns
      patterns = if String.contains?(content, "defmodule"), do: [%{type: "Module", description: "Standard Elixir module"} | patterns], else: patterns
      patterns = if String.contains?(content, "use Phoenix.LiveView"), do: [%{type: "LiveView", description: "Phoenix LiveView integration"} | patterns], else: patterns
      patterns = if String.contains?(content, "use Ecto.Schema"), do: [%{type: "Schema", description: "Ecto schema definition"} | patterns], else: patterns
      patterns = if String.contains?(content, "@spec"), do: [%{type: "Typespec", description: "Type specifications"} | patterns], else: patterns
      
      patterns
    else
      []
    end
  end
  
  defp analyze_transformation(haxe_content, elixir_content) do
    cond do
      haxe_content && elixir_content ->
        haxe_lines = length(String.split(haxe_content, "\\n"))
        elixir_lines = length(String.split(elixir_content, "\\n"))
        
        ratio = elixir_lines / max(haxe_lines, 1)
        
        complexity = cond do
          ratio > 3.0 -> "High (significant expansion)"
          ratio > 1.5 -> "Medium (moderate expansion)" 
          ratio < 0.7 -> "Low (code compression)"
          true -> "Balanced (1:1 mapping)"
        end
        
        pattern = cond do
          String.contains?(haxe_content, "@:liveview") -> "LiveView Generation"
          String.contains?(haxe_content, "@:schema") -> "Schema Generation"
          String.contains?(haxe_content, "@:genserver") -> "GenServer Generation"
          String.contains?(haxe_content, "class ") -> "Class to Module"
          true -> "Standard Transformation"
        end
        
        %{
          pattern: pattern,
          complexity: complexity,
          expansion_ratio: Float.round(ratio, 2)
        }
        
      true ->
        %{
          pattern: "Unknown",
          complexity: "Cannot analyze",
          expansion_ratio: 0.0
        }
    end
  end
  
  defp get_mapping_summary(source_map) do
    if source_map do
      %{
        total_mappings: length(source_map.mappings),
        source_files: source_map.sources,
        coverage: "Detailed position mapping available"
      }
    else
      nil
    end
  end
  
  defp build_cross_reference_data(_haxe_content, _elixir_content, source_map, _opts) do
    %{
      bidirectional_available: source_map != nil,
      haxe_to_elixir: if(source_map, do: "Available via source mapping", else: "Estimated only"),
      elixir_to_haxe: if(source_map, do: "Available via reverse lookup", else: "Not available"),
      navigation_commands: [
        "mix haxe.source_map FILE LINE COLUMN",
        "mix haxe.inspect FILE --compare",
        "mix haxe.stacktrace ERROR_ID --cross-reference"
      ]
    }
  end
  
  defp build_llm_recommendations(data) do
    cond do
      !data.files.haxe.exists ->
        %{
          primary_focus: "Missing Haxe source file",
          debug_level: "FILE_SYSTEM",
          actions: [
            "Verify Haxe source file path is correct",
            "Check if file is in expected source directory",
            "Ensure file was not moved or deleted"
          ],
          related_commands: ["mix haxe.inspect --list-files"]
        }
        
      !data.files.elixir.exists ->
        %{
          primary_focus: "Missing generated Elixir file",
          debug_level: "COMPILATION",
          actions: [
            "Compile Haxe source with: haxe build.hxml",
            "Check compilation errors for this specific file",
            "Verify output directory configuration"
          ],
          related_commands: ["mix compile", "mix haxe.errors"]
        }
        
      length(data.analysis.haxe_annotations) > 0 ->
        %{
          primary_focus: "Annotation-driven code generation",
          debug_level: "HAXE_ANNOTATIONS",
          actions: [
            "Review annotation usage and parameters",
            "Check if annotations are correctly implemented",
            "Verify generated code follows annotation intent"
          ],
          related_commands: ["mix haxe.inspect FILE --show-annotations"]
        }
        
      true ->
        %{
          primary_focus: "Standard Haxe to Elixir transformation",
          debug_level: "HAXE_SOURCE",
          actions: [
            "Debug issues at Haxe source level",
            "Check type annotations and function signatures",
            "Verify Haxe syntax and logic correctness"
          ],
          related_commands: [
            "mix haxe.inspect FILE --compare",
            "mix haxe.source_map FILE LINE COLUMN"
          ]
        }
    end
  end
  
  defp describe_annotation(annotation) do
    case annotation do
      "liveview" -> "Phoenix LiveView component generation"
      "schema" -> "Ecto schema module generation"
      "changeset" -> "Ecto changeset validation generation"
      "genserver" -> "OTP GenServer behavior generation"
      "migration" -> "Ecto migration generation"
      "template" -> "Phoenix template component generation"
      "query" -> "Ecto query macro generation"
      "native" -> "Native code injection"
      _ -> "Custom annotation"
    end
  end
  
  defp find_elixir_file_for_haxe(haxe_file, target_dirs) when is_list(target_dirs) do
    base_name = Path.basename(haxe_file, ".hx")
    
    Enum.find_value(target_dirs, fn dir ->
      potential_file = Path.join(dir, base_name <> ".ex")
      if File.exists?(potential_file), do: potential_file, else: nil
    end) || Path.join(hd(target_dirs), base_name <> ".ex")
  end
  
  defp find_elixir_file_for_haxe(haxe_file, target_dir) when is_binary(target_dir) do
    base_name = Path.basename(haxe_file, ".hx")
    Path.join(target_dir, base_name <> ".ex")
  end
  
  defp find_haxe_file_for_elixir(elixir_file, target_dirs) when is_list(target_dirs) do
    base_name = Path.basename(elixir_file, ".ex")
    
    Enum.find_value(target_dirs, fn dir ->
      potential_file = Path.join(dir, base_name <> ".hx")
      if File.exists?(potential_file), do: potential_file, else: nil
    end) || Path.join(hd(target_dirs), base_name <> ".hx")
  end
  
  defp find_haxe_file_for_elixir(elixir_file, target_dir) when is_binary(target_dir) do
    base_name = Path.basename(elixir_file, ".ex")
    Path.join(target_dir, base_name <> ".hx")
  end
  
  defp get_project_directories do
    # Return common project directories
    ["src", "src_haxe", "lib", "test", "."]
  end
  
  defp find_all_haxe_elixir_pairs(target_dirs) when is_list(target_dirs) do
    target_dirs
    |> Enum.flat_map(&find_all_haxe_elixir_pairs/1)
    |> Enum.uniq()
  end
  
  defp find_all_haxe_elixir_pairs(target_dir) when is_binary(target_dir) do
    if File.exists?(target_dir) do
      haxe_files = Path.wildcard(Path.join(target_dir, "**/*.hx"))
      
      Enum.flat_map(haxe_files, fn haxe_file ->
        elixir_file = find_elixir_file_for_haxe(haxe_file, target_dir)
        source_map_file = elixir_file <> ".map"
        
        if File.exists?(elixir_file) do
          [{haxe_file, elixir_file, source_map_file}]
        else
          []
        end
      end)
    else
      []
    end
  end
  
  defp suggest_file_alternatives(file, _opts) do
    Mix.shell().info("")
    Mix.shell().info("💡 Suggestions:")
    Mix.shell().info("   • List all available pairs: mix haxe.inspect --list-files")
    Mix.shell().info("   • Verify file path: #{file}")
    
    case Path.extname(file) do
      ".hx" ->
        Mix.shell().info("   • Compile to generate Elixir: haxe build.hxml")
        Mix.shell().info("   • Check compilation errors: mix haxe.errors")
        
      ".ex" ->
        Mix.shell().info("   • Find corresponding Haxe source in src/ directories")
        Mix.shell().info("   • Generated files should be in lib/ directory")
        
      _ ->
        Mix.shell().info("   • File must have .hx (Haxe) or .ex (Elixir) extension")
    end
  end
  
  defp show_usage do
    Mix.shell().info("Usage: mix haxe.inspect FILE [options]")
    Mix.shell().info("       mix haxe.inspect --list-files")
    Mix.shell().info("       mix haxe.inspect --analyze-patterns")
    Mix.shell().info("")
    Mix.shell().info("For help: mix haxe.inspect --help")
  end
  
  defp show_help do
    Mix.shell().info("mix haxe.inspect - Cross-reference inspection for Haxe↔Elixir code")
    Mix.shell().info("")
    Mix.shell().info("Usage:")
    Mix.shell().info("  mix haxe.inspect FILE [options]")
    Mix.shell().info("  mix haxe.inspect --list-files")
    Mix.shell().info("  mix haxe.inspect --analyze-patterns")
    Mix.shell().info("")
    Mix.shell().info("Arguments:")
    Mix.shell().info("  FILE            Haxe source file (.hx) or generated Elixir file (.ex)")
    Mix.shell().info("")
    Mix.shell().info("Options:")
    Mix.shell().info("  --with-mappings     Include detailed source mapping information")
    Mix.shell().info("  --compare           Side-by-side comparison of source and generated code")
    Mix.shell().info("  --format FORMAT     Output format: detailed, json, table (default: detailed)")
    Mix.shell().info("  --json              Alias for --format json")
    Mix.shell().info("  --analyze-patterns  Analyze common Haxe→Elixir transformation patterns")
    Mix.shell().info("  --list-files        List all available Haxe/Elixir file pairs")
    Mix.shell().info("  --show-annotations  Show annotations and metadata transformations")
    Mix.shell().info("  --context LINES     Number of context lines to show (default: 3)")
    Mix.shell().info("  --target-dir DIR    Directory to search for files (default: current project)")
    Mix.shell().info("  --help              Show this help")
    Mix.shell().info("")
    Mix.shell().info("Examples:")
    Mix.shell().info("  mix haxe.inspect src/UserService.hx")
    Mix.shell().info("  mix haxe.inspect src/UserService.hx --with-mappings")
    Mix.shell().info("  mix haxe.inspect src/UserService.hx --compare")
    Mix.shell().info("  mix haxe.inspect lib/UserService.ex --format json")
    Mix.shell().info("  mix haxe.inspect --list-files")
    Mix.shell().info("  mix haxe.inspect --analyze-patterns")
  end
end
