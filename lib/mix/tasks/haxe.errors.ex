defmodule Mix.Tasks.Haxe.Errors do
  @moduledoc """
  Displays Haxe compilation errors in structured format for LLM agent debugging.
  
  This task provides programmatic access to compilation errors with detailed
  stacktrace information and cross-level debugging support.
  
  ## Usage
  
      mix haxe.errors
      mix haxe.errors --format json
      mix haxe.errors --json
      mix haxe.errors --format table
      mix haxe.errors --recent 10
      mix haxe.errors --filter error
      mix haxe.errors --file User.hx
      mix haxe.errors --line 23
  
  ## Output Formats
  
    * `table` - Human-readable table format (default)
    * `json` - Machine-readable JSON for LLM agents
    * `detailed` - Full error context with suggestions
  
  ## Filtering Options
  
    * `--recent N` - Show only the N most recent errors
    * `--filter TYPE` - Filter by error type (error, warning, stacktrace)
    * `--file FILE` - Show only errors from specific file
    * `--line LINE` - Show only errors at specific line number
    * `--level LEVEL` - Show errors at specific abstraction level (haxe, elixir, mix)
  
  ## LLM Agent Usage
  
  For autonomous debugging, LLM agents should use JSON format:
  
      mix haxe.errors --format json --recent 5
  
  This provides structured error data that can be programmatically parsed
  and used for automated debugging decisions.
  """
  
  use Mix.Task

  @shortdoc "Displays Haxe compilation errors in structured format"

  @switches [
    format: :string,
    json: :boolean,
    recent: :integer,
    filter: :string,
    file: :string,
    line: :integer,
    level: :string,
    help: :boolean
  ]

  @aliases [
    f: :format,
    j: :json,
    r: :recent,
    h: :help
  ]

  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      display_errors(normalize_opts(opts))
    end
  end

  defp display_errors(opts) do
    errors = HaxeCompiler.get_compilation_errors(:map)
    
    filtered_errors = errors
    |> apply_filters(opts)
    |> limit_recent(opts[:recent])

    format = opts[:format] || "table"
    
    case format do
      "json" ->
        display_json(filtered_errors)
        
      "table" ->
        display_table(filtered_errors)
        
      "detailed" ->
        display_detailed(filtered_errors)
        
      other ->
        Mix.shell().error("Unknown format: #{other}")
        Mix.shell().error("Available formats: json, table, detailed")
    end
  end

  defp normalize_opts(opts) do
    if Keyword.get(opts, :json, false), do: Keyword.put(opts, :format, "json"), else: opts
  end

  defp apply_filters(errors, opts) do
    errors
    |> filter_by_type(opts[:filter])
    |> filter_by_file(opts[:file])
    |> filter_by_line(opts[:line])
    |> filter_by_level(opts[:level])
  end

  defp filter_by_type(errors, nil), do: errors
  defp filter_by_type(errors, type) do
    type_atom =
      case String.downcase(String.trim(type)) do
        "error" -> :compilation_error
        "compilation_error" -> :compilation_error
        "warning" -> :warning
        "stacktrace" -> :stacktrace
        other -> String.to_atom(other)
      end

    Enum.filter(errors, fn error -> error.type == type_atom end)
  end

  defp filter_by_file(errors, nil), do: errors
  defp filter_by_file(errors, file) do
    Enum.filter(errors, fn error ->
      Map.get(error, :file, "") |> String.contains?(file)
    end)
  end

  defp filter_by_line(errors, nil), do: errors
  defp filter_by_line(errors, line) do
    Enum.filter(errors, fn error ->
      Map.get(error, :line) == line
    end)
  end

  defp filter_by_level(errors, nil), do: errors
  defp filter_by_level(errors, level) do
    level_atom = String.to_atom(level)
    Enum.filter(errors, fn error ->
      Map.get(error, :level) == level_atom
    end)
  end

  defp limit_recent(errors, nil), do: errors
  defp limit_recent(errors, count) do
    errors
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    |> Enum.take(count)
  end

  defp display_json(errors) do
    if Code.ensure_loaded?(Jason) do
      case Jason.encode(errors, pretty: true) do
        {:ok, json} ->
          IO.puts(json)
          
        {:error, reason} ->
          Mix.shell().error("Failed to encode errors as JSON: #{inspect(reason)}")
      end
    else
      Mix.shell().error("Jason library not available. Cannot output JSON format.")
      Mix.shell().info("Install Jason with: mix deps.get")
    end
  end

  defp display_table(errors) do
    if Enum.empty?(errors) do
      Mix.shell().info("✅ No compilation errors found")
    else
      Mix.shell().info("📋 Compilation Errors (#{length(errors)} total)")
      Mix.shell().info("")
      
      errors
      |> Enum.with_index(1)
      |> Enum.each(&display_error_row/1)
    end
  end

  defp display_detailed(errors) do
    if Enum.empty?(errors) do
      Mix.shell().info("✅ No compilation errors found")
    else
      Mix.shell().info("🔍 Detailed Compilation Error Analysis")
      Mix.shell().info("=" |> String.duplicate(50))
      Mix.shell().info("")
      
      errors
      |> Enum.with_index(1)
      |> Enum.each(&display_detailed_error/1)
    end
  end

  defp display_error_row({error, index}) do
    type_icon = case error.type do
      :compilation_error -> "❌"
      :warning -> "⚠️"
      :stacktrace -> "📚"
      _ -> "❓"
    end
    
    file = Map.get(error, :file, "unknown")
    line = Map.get(error, :line, "?")
    error_type = Map.get(error, :error_type, "Unknown")
    message = Map.get(error, :message, "No message")
    
    Mix.shell().info("#{index}. #{type_icon} #{file}:#{line} - #{error_type}")
    Mix.shell().info("   #{String.slice(message, 0, 80)}#{if String.length(message) > 80, do: "...", else: ""}")
    Mix.shell().info("")
  end

  defp display_detailed_error({error, index}) do
    Mix.shell().info("Error ##{index}: #{error.error_id}")
    Mix.shell().info("-" |> String.duplicate(40))
    
    display_error_field("Type", error.type)
    display_error_field("Level", error.level)
    display_error_field("File", error.file)
    display_error_field("Line", error.line)
    
    if error.column_start do
      display_error_field("Column", "#{error.column_start}-#{error.column_end}")
    end
    
    display_error_field("Error Type", error.error_type)
    display_error_field("Message", error.message)
    display_error_field("Timestamp", error.timestamp)
    
    # LLM debugging suggestions
    display_debugging_suggestions(error)
    
    Mix.shell().info("")
  end

  defp display_error_field(_label, nil), do: :ok
  defp display_error_field(label, value) do
    Mix.shell().info("#{String.pad_trailing(label <> ":", 12)} #{value}")
  end

  defp display_debugging_suggestions(error) do
    Mix.shell().info("")
    Mix.shell().info("🤖 LLM Debugging Guidance:")
    
    case error.level do
      :haxe ->
        Mix.shell().info("   • Debug at HAXE level - fix source #{error.file}")
        Mix.shell().info("   • This is a compilation error, not runtime error")
        Mix.shell().info("   • Check imports, types, and syntax in .hx file")
        
      :elixir ->
        Mix.shell().info("   • Debug at ELIXIR level - inspect generated code")
        Mix.shell().info("   • Use: mix haxe.inspect #{error.file}")
        Mix.shell().info("   • This is runtime error after successful compilation")
        
      _ ->
        Mix.shell().info("   • Use mix haxe.status to check compilation level")
    end
    
    # File-specific suggestions
    if error.file && String.contains?(error.file, "LiveView") do
      Mix.shell().info("   • LiveView specific - check @:liveview annotation")
      Mix.shell().info("   • Verify handle_event patterns and socket management")
    end
  end

  defp show_help do
    Mix.shell().info("mix haxe.errors - Display Haxe compilation errors")
    Mix.shell().info("")
    Mix.shell().info("Usage:")
    Mix.shell().info("  mix haxe.errors [options]")
    Mix.shell().info("")
    Mix.shell().info("Options:")
    Mix.shell().info("  --format FORMAT    Output format: json, table, detailed (default: table)")
    Mix.shell().info("  --json             Alias for --format json")
    Mix.shell().info("  --recent N         Show N most recent errors")
    Mix.shell().info("  --filter TYPE      Filter by type: error, warning, stacktrace")
    Mix.shell().info("  --file FILE        Show errors from specific file")
    Mix.shell().info("  --line LINE        Show errors at specific line")
    Mix.shell().info("  --level LEVEL      Show errors at level: haxe, elixir, mix")
    Mix.shell().info("  --help             Show this help")
    Mix.shell().info("")
    Mix.shell().info("Examples:")
    Mix.shell().info("  mix haxe.errors --format json")
    Mix.shell().info("  mix haxe.errors --recent 5 --filter error")
    Mix.shell().info("  mix haxe.errors --file User.hx --format detailed")
  end
end
