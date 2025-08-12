defmodule Mix.Tasks.Haxe.Stacktrace do
  @moduledoc """
  Displays detailed stacktrace information for specific Haxe compilation errors.
  
  This task provides deep stacktrace analysis for LLM agents to understand
  the call chain that led to compilation errors and make informed debugging
  decisions at the appropriate abstraction level.
  
  ## Usage
  
      mix haxe.stacktrace ERROR_ID
      mix haxe.stacktrace ERROR_ID --format json
      mix haxe.stacktrace ERROR_ID --with-context
      mix haxe.stacktrace ERROR_ID --cross-reference
  
  ## Options
  
    * `--format FORMAT` - Output format: table, json, detailed (default: detailed)
    * `--with-context` - Include source code context around each stack frame
    * `--cross-reference` - Show how Haxe stack frames map to Elixir code
    * `--trace-generation` - Show code generation path from Haxe to Elixir
  
  ## LLM Agent Usage
  
  LLM agents should first get error IDs using `mix haxe.errors --format json`,
  then use this task for detailed stacktrace analysis:
  
      # 1. Get errors with IDs
      mix haxe.errors --format json --recent 5
      
      # 2. Analyze specific error stacktrace
      mix haxe.stacktrace haxe_error_123456_0 --format json
      
      # 3. Get cross-level debugging info
      mix haxe.stacktrace haxe_error_123456_0 --cross-reference
  """
  
  use Mix.Task

  @shortdoc "Display detailed stacktrace for specific compilation error"

  @switches [
    format: :string,
    with_context: :boolean,
    cross_reference: :boolean,
    trace_generation: :boolean,
    help: :boolean
  ]

  @aliases [
    f: :format,
    c: :with_context,
    x: :cross_reference,
    t: :trace_generation,
    h: :help
  ]

  def run([]), do: show_usage()
  def run(["--help"]), do: show_help()
  
  def run([error_id | rest]) do
    {opts, _} = OptionParser.parse!(rest, strict: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      display_stacktrace(error_id, opts)
    end
  end

  def run(_), do: show_usage()

  defp display_stacktrace(error_id, opts) do
    case find_error_by_id(error_id) do
      nil ->
        Mix.shell().error("Error ID not found: #{error_id}")
        Mix.shell().error("Use 'mix haxe.errors' to see available error IDs")
        
      error ->
        format = opts[:format] || "detailed"
        
        case format do
          "json" ->
            display_json_stacktrace(error, opts)
            
          "table" ->
            display_table_stacktrace(error, opts)
            
          "detailed" ->
            display_detailed_stacktrace(error, opts)
            
          other ->
            Mix.shell().error("Unknown format: #{other}")
            Mix.shell().error("Available formats: json, table, detailed")
        end
    end
  end

  defp find_error_by_id(error_id) do
    errors = HaxeCompiler.get_compilation_errors(:map)
    Enum.find(errors, fn error -> 
      Map.get(error, :error_id) == error_id 
    end)
  end

  defp display_json_stacktrace(error, opts) do
    if Code.ensure_loaded?(Jason) do
      stacktrace_data = build_stacktrace_data(error, opts)
      
      case Jason.encode(stacktrace_data, pretty: true) do
        {:ok, json} ->
          IO.puts(json)
          
        {:error, reason} ->
          Mix.shell().error("Failed to encode stacktrace as JSON: #{inspect(reason)}")
      end
    else
      Mix.shell().error("Jason library not available. Cannot output JSON format.")
      Mix.shell().info("Install Jason with: mix deps.get")
    end
  end

  defp display_table_stacktrace(error, opts) do
    Mix.shell().info("📚 Stacktrace for Error: #{error.error_id}")
    Mix.shell().info("=" |> String.duplicate(60))
    Mix.shell().info("")
    
    display_error_summary(error)
    
    stacktrace_entries = get_stacktrace_entries(error, opts)
    
    if Enum.empty?(stacktrace_entries) do
      Mix.shell().info("   No stacktrace information available")
    else
      Mix.shell().info("Call Stack:")
      stacktrace_entries
      |> Enum.with_index(1)
      |> Enum.each(&display_stack_frame/1)
    end
    
    if opts[:cross_reference] do
      display_cross_reference(error)
    end
  end

  defp display_detailed_stacktrace(error, opts) do
    Mix.shell().info("🔍 Detailed Stacktrace Analysis")
    Mix.shell().info("=" |> String.duplicate(50))
    Mix.shell().info("")
    
    display_error_summary(error)
    
    stacktrace_entries = get_stacktrace_entries(error, opts)
    
    Mix.shell().info("📚 Call Stack Analysis:")
    Mix.shell().info("")
    
    if Enum.empty?(stacktrace_entries) do
      Mix.shell().info("   ℹ️  No explicit stacktrace information available")
      Mix.shell().info("   💡 This is a compilation-time error, not a runtime error")
      Mix.shell().info("")
    else
      stacktrace_entries
      |> Enum.with_index(1)
      |> Enum.each(&display_detailed_frame/1)
    end
    
    display_debugging_recommendations(error, opts)
    
    if opts[:cross_reference] do
      display_cross_reference(error)
    end
    
    if opts[:trace_generation] do
      display_generation_trace(error)
    end
  end

  defp build_stacktrace_data(error, opts) do
    base_data = %{
      error_id: error.error_id,
      type: error.type,
      level: error.level,
      file: error.file,
      line: error.line,
      message: error.message,
      stacktrace: get_stacktrace_entries(error, opts),
      debugging_guidance: build_debugging_guidance(error),
      timestamp: error.timestamp
    }
    
    enhanced_data = if opts[:cross_reference] do
      Map.put(base_data, :cross_reference, build_cross_reference_data(error))
    else
      base_data
    end
    
    if opts[:with_context] do
      Map.put(enhanced_data, :source_context, get_source_context(error))
    else
      enhanced_data
    end
  end

  defp get_stacktrace_entries(error, _opts) do
    # For now, return the stacktrace stored in the error
    # In future, this could be enhanced with more detailed call stack analysis
    Map.get(error, :stacktrace, [])
  end

  defp display_error_summary(error) do
    Mix.shell().info("Error Summary:")
    Mix.shell().info("  ID: #{error.error_id}")
    Mix.shell().info("  Type: #{error.type} (#{error.level} level)")
    Mix.shell().info("  File: #{error.file}:#{error.line}")
    if error.column_start do
      Mix.shell().info("  Column: #{error.column_start}-#{error.column_end}")
    end
    Mix.shell().info("  Message: #{error.message}")
    Mix.shell().info("")
  end

  defp display_stack_frame({frame, index}) do
    case frame.type do
      :stacktrace ->
        Mix.shell().info("  #{index}. #{frame.function_call}")
        Mix.shell().info("      at #{frame.file}:#{frame.line}")
        
      _ ->
        Mix.shell().info("  #{index}. #{frame.type}")
        if Map.has_key?(frame, :file) do
          Mix.shell().info("      at #{frame.file}:#{Map.get(frame, :line, "?")}")
        end
    end
  end

  defp display_detailed_frame({frame, index}) do
    Mix.shell().info("#{index}. Stack Frame Analysis")
    Mix.shell().info("   " <> ("-" |> String.duplicate(25)))
    
    case frame.type do
      :stacktrace ->
        Mix.shell().info("   Function: #{frame.function_call}")
        Mix.shell().info("   Location: #{frame.file}:#{frame.line}")
        Mix.shell().info("   Level: #{frame.level}")
        
      _ ->
        Mix.shell().info("   Type: #{frame.type}")
        if Map.has_key?(frame, :file) do
          Mix.shell().info("   Location: #{frame.file}:#{Map.get(frame, :line, "?")}")
        end
    end
    
    # Show debugging recommendations for this frame
    Mix.shell().info("   🤖 Debug Action: #{get_frame_debug_action(frame)}")
    Mix.shell().info("")
  end

  defp get_frame_debug_action(frame) do
    case frame.level do
      :haxe -> "Inspect Haxe source at #{frame.file}:#{Map.get(frame, :line, "?")}"
      :elixir -> "Check generated Elixir code (use mix haxe.inspect)"
      _ -> "Review #{frame.type} in #{Map.get(frame, :file, "unknown location")}"
    end
  end

  defp display_debugging_recommendations(error, _opts) do
    Mix.shell().info("🤖 LLM Agent Debugging Recommendations:")
    Mix.shell().info("")
    
    guidance = build_debugging_guidance(error)
    
    Mix.shell().info("   Primary Action: #{guidance.primary_action}")
    Mix.shell().info("   Debug Level: #{guidance.debug_level}")
    Mix.shell().info("   Next Steps:")
    
    guidance.next_steps
    |> Enum.with_index(1)
    |> Enum.each(fn {step, i} ->
      Mix.shell().info("     #{i}. #{step}")
    end)
    
    if guidance.related_commands do
      Mix.shell().info("")
      Mix.shell().info("   Related Commands:")
      Enum.each(guidance.related_commands, fn cmd ->
        Mix.shell().info("     • #{cmd}")
      end)
    end
    
    Mix.shell().info("")
  end

  defp build_debugging_guidance(error) do
    case error.level do
      :haxe ->
        %{
          primary_action: "Fix source code in #{error.file}",
          debug_level: "HAXE (source level)",
          next_steps: [
            "Check imports and type definitions",
            "Verify function signatures match usage",
            "Look for typos in type/variable names",
            "Ensure required annotations are present"
          ],
          related_commands: [
            "mix haxe.inspect #{error.file}",
            "mix haxe.errors --file #{error.file}"
          ]
        }
        
      :elixir ->
        %{
          primary_action: "Inspect generated Elixir code",
          debug_level: "ELIXIR (target level)",
          next_steps: [
            "Check generated .ex file patterns",
            "Verify Phoenix/Ecto integration",
            "Compare with expected Elixir idioms",
            "Report compiler bug if generation is wrong"
          ],
          related_commands: [
            "mix haxe.inspect #{error.file}",
            "mix haxe.map #{error.file} #{error.line}"
          ]
        }
        
      _ ->
        %{
          primary_action: "Determine error abstraction level",
          debug_level: "UNKNOWN",
          next_steps: [
            "Run mix haxe.status to check compilation state",
            "Use mix haxe.errors --format json for structured info",
            "Identify if this is compilation or runtime error"
          ],
          related_commands: [
            "mix haxe.status --format json",
            "mix haxe.errors --recent 5"
          ]
        }
    end
  end

  defp display_cross_reference(error) do
    Mix.shell().info("🔗 Cross-Level Reference:")
    Mix.shell().info("")
    
    case Map.get(error, :source_mapping) do
      nil ->
        # Fallback to estimated mapping
        Mix.shell().info("   Haxe Source: #{error.file}:#{error.line}")
        elixir_file = String.replace(error.file, ".hx", ".ex")
        Mix.shell().info("   Generated Target: #{elixir_file} (estimated)")
        Mix.shell().info("   ℹ️  Source mapping not available")
        
      source_mapping ->
        # Use actual source mapping information
        original = source_mapping.original_haxe
        generated = source_mapping.generated_elixir
        
        Mix.shell().info("   📄 Haxe Source: #{original.file}:#{original.line}:#{original.column}")
        Mix.shell().info("   ⚡ Generated Elixir: #{generated.file}:#{generated.line}:#{generated.column}")
        Mix.shell().info("   🗺️  Source Map: #{Path.basename(source_mapping.source_map_file)}")
        Mix.shell().info("   ✅ Accurate position mapping available")
    end
    
    Mix.shell().info("")
  end

  defp display_generation_trace(error) do
    Mix.shell().info("🔄 Code Generation Trace:")
    Mix.shell().info("")
    Mix.shell().info("   1. Haxe Compilation: #{error.file} → AST")
    Mix.shell().info("   2. Reflaxe Transform: AST → Elixir AST")
    Mix.shell().info("   3. Elixir Generation: Elixir AST → .ex file")
    Mix.shell().info("   4. Mix Compilation: .ex → BEAM bytecode")
    Mix.shell().info("")
    Mix.shell().info("   Error occurred at step 1 (Haxe Compilation)")
    Mix.shell().info("   → Debug at HAXE level in #{error.file}")
    Mix.shell().info("")
  end

  defp build_cross_reference_data(error) do
    case Map.get(error, :source_mapping) do
      nil ->
        # Fallback to estimated mapping
        elixir_file = String.replace(error.file, ".hx", ".ex")
        %{
          haxe_source: %{
            file: error.file,
            line: error.line,
            column_start: error.column_start,
            column_end: error.column_end
          },
          elixir_target: %{
            file: elixir_file,
            estimated: true,
            note: "Source mapping not available - positions are estimated"
          }
        }
        
      source_mapping ->
        # Use actual source mapping information
        %{
          haxe_source: source_mapping.original_haxe,
          elixir_target: source_mapping.generated_elixir,
          source_map: %{
            file: source_mapping.source_map_file,
            accurate: true,
            note: "Accurate position mapping from source map"
          }
        }
    end
  end

  defp get_source_context(error) do
    case Map.get(error, :source_mapping) do
      nil ->
        # Use original file information
        get_file_context(error.file, error.line)
        
      source_mapping ->
        # Use Haxe source file with accurate position
        original = source_mapping.original_haxe
        context = get_file_context(original.file, original.line)
        
        Map.merge(context, %{
          source_mapping_used: true,
          generated_file: source_mapping.generated_elixir.file,
          generated_line: source_mapping.generated_elixir.line
        })
    end
  end
  
  defp get_file_context(file_path, line_number) do
    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          lines = String.split(content, "\n")
          total_lines = length(lines)
          
          # Show 3 lines before and after the error line
          start_line = max(1, line_number - 3)
          end_line = min(total_lines, line_number + 3)
          
          context_lines = 
            lines
            |> Enum.with_index(1)
            |> Enum.filter(fn {_line, index} -> 
              index >= start_line and index <= end_line
            end)
            |> Enum.map(fn {line, index} ->
              marker = if index == line_number, do: ">>> ", else: "    "
              %{
                line_number: index,
                content: line,
                is_error_line: index == line_number,
                formatted: "#{String.pad_leading(Integer.to_string(index), 4)} #{marker}#{line}"
              }
            end)
          
          %{
            file: file_path,
            line: line_number,
            context_available: true,
            context_lines: context_lines,
            total_lines: total_lines
          }
          
        {:error, _} ->
          %{
            file: file_path,
            line: line_number,
            context_available: false,
            error: "Failed to read source file"
          }
      end
    else
      %{
        file: file_path,
        line: line_number,
        context_available: false,
        error: "Source file not found"
      }
    end
  end

  defp show_usage do
    Mix.shell().info("Usage: mix haxe.stacktrace ERROR_ID [options]")
    Mix.shell().info("")
    Mix.shell().info("Get error IDs with: mix haxe.errors --format json")
    Mix.shell().info("For help: mix haxe.stacktrace --help")
  end

  defp show_help do
    Mix.shell().info("mix haxe.stacktrace - Display detailed stacktrace for compilation error")
    Mix.shell().info("")
    Mix.shell().info("Usage:")
    Mix.shell().info("  mix haxe.stacktrace ERROR_ID [options]")
    Mix.shell().info("")
    Mix.shell().info("Options:")
    Mix.shell().info("  --format FORMAT        Output format: json, table, detailed (default: detailed)")
    Mix.shell().info("  --with-context         Include source code context")
    Mix.shell().info("  --cross-reference      Show Haxe to Elixir mapping")
    Mix.shell().info("  --trace-generation     Show code generation path")
    Mix.shell().info("  --help                 Show this help")
    Mix.shell().info("")
    Mix.shell().info("Examples:")
    Mix.shell().info("  mix haxe.stacktrace haxe_error_123456_0")
    Mix.shell().info("  mix haxe.stacktrace haxe_error_123456_0 --format json")
    Mix.shell().info("  mix haxe.stacktrace haxe_error_123456_0 --cross-reference")
  end
end