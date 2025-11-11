defmodule Mix.Tasks.Compile.Haxe do
  @moduledoc """
  Compiles Haxe files to Elixir using Reflaxe.Elixir.
  
  This task integrates Haxe compilation into the Mix build pipeline,
  ensuring proper build order and dependency resolution.
  
  ## Configuration
  
  Add to your `mix.exs`:
  
      def project do
        [
          compilers: [:haxe] ++ Mix.compilers(),
          haxe: [
            hxml_file: "build.hxml",
            source_dir: "src",
            target_dir: "lib",
            watch: true,
            verbose: false
          ]
        ]
      end
  
  ## Options
  
    * `:hxml_file` - Path to HXML build file (default: "build.hxml")
    * `:source_dir` - Source directory for Haxe files (default: "src")
    * `:target_dir` - Target directory for Elixir files (default: "lib")
    * `:watch` - Enable file watching in dev environment (default: true)
    * `:verbose` - Enable verbose output (default: false)
    * `:force` - Force recompilation (default: false)
  
  ## Command line options
  
    * `--force` - Force full recompilation
    * `--verbose` - Show detailed compilation output
    * `--no-watch` - Disable file watching even in dev
  
  """
  
  use Mix.Task.Compiler
  
  @recursive true
  @requirements ["loadpaths"]
  
  @impl Mix.Task.Compiler
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, 
      switches: [force: :boolean, verbose: :boolean, no_watch: :boolean]
    )
    
    config = get_haxe_config()
    config = Keyword.merge(config, opts)
    
    # Ensure required directories exist
    ensure_directories(config)
    
    # Check if compilation is needed
    if should_compile?(config) do
      compile_haxe(config)
    else
      if config[:verbose] do
        Mix.shell().info("Haxe files are up to date")
      end
      {:ok, []}
    end
  end
  
  @impl Mix.Task.Compiler
  def clean do
    config = get_haxe_config()
    target_dir = Keyword.get(config, :target_dir, "lib")
    
    # Remove generated Elixir files
    if File.exists?(target_dir) do
      Mix.shell().info("Cleaning generated Elixir files from #{target_dir}")
      
      # Find all generated .ex files and remove them
      generated_files = Path.join(target_dir, "**/*.ex")
      |> Path.wildcard()
      |> Enum.filter(&generated_file?/1)
      
      Enum.each(generated_files, &File.rm!/1)
      Mix.shell().info("Cleaned #{length(generated_files)} generated files")
    end
    
    # Clear compilation error cache
    HaxeCompiler.clear_compilation_errors()
  end
  
  @impl Mix.Task.Compiler
  def manifests do
    [manifest_path()]
  end
  
  # Private functions
  
  defp get_haxe_config do
    Mix.Project.config()
    |> Keyword.get(:haxe, [])
    |> Keyword.put_new(:hxml_file, "build.hxml")
    |> Keyword.put_new(:source_dir, "src_haxe")
    |> Keyword.put_new(:target_dir, "lib")
    |> Keyword.put_new(:watch, Mix.env() == :dev)
    |> Keyword.put_new(:verbose, false)
    |> Keyword.put_new(:force, false)
  end
  
  defp ensure_directories(config) do
    source_dir = Keyword.get(config, :source_dir)
    target_dir = Keyword.get(config, :target_dir)
    
    # Create source directory if it doesn't exist
    unless File.exists?(source_dir) do
      File.mkdir_p!(source_dir)
      Mix.shell().info("Created source directory: #{source_dir}")
    end
    
    # Create target directory if it doesn't exist  
    unless File.exists?(target_dir) do
      File.mkdir_p!(target_dir)
      Mix.shell().info("Created target directory: #{target_dir}")
    end
    
    # Create haxe_libraries directory if it doesn't exist (for lix)
    unless File.exists?("haxe_libraries") do
      File.mkdir_p!("haxe_libraries")
    end
  end
  
  defp should_compile?(config) do
    cond do
      # Force compilation flag
      config[:force] ->
        true
      
      # No manifest means first compilation
      not File.exists?(manifest_path()) ->
        true
      
      # Check if any source files changed
      true ->
        HaxeCompiler.needs_recompilation?(config)
    end
  end
  
  defp compile_haxe(config) do
    Mix.shell().info("Compiling Haxe files...")
    # Automatically start the Haxe compilation server in dev-like envs
    # unless the user opts out via HAXE_NO_SERVER=1. This is transparent
    # and falls back cleanly to direct compilation on any failure.
    if (Mix.env() in [:dev, :test, :e2e]) and System.get_env("HAXE_NO_SERVER") != "1" do
      try do
        unless HaxeServer.running?() do
          {:ok, _} = HaxeServer.start_link([])
        end
      rescue
        _ -> :ok
      end
    end
    
    # Start file watcher if enabled and in dev environment
    if config[:watch] && Mix.env() == :dev && !config[:no_watch] do
      start_file_watcher(config)
    end
    
    # Perform compilation
    case HaxeCompiler.compile(config) do
      {:ok, compiled_files} ->
        # Store manifest for incremental compilation
        write_manifest(compiled_files)
        
        # Report success
        if config[:verbose] || !Enum.empty?(compiled_files) do
          Mix.shell().info("Compiled #{length(compiled_files)} Haxe file(s)")
        end
        
        # Return diagnostics if there were warnings
        diagnostics = get_compilation_diagnostics()
        if Enum.empty?(diagnostics) do
          {:ok, compiled_files}
        else
          {:ok, diagnostics}
        end
      
      {:error, reason} ->
        # Parse and enhance error message
        errors = parse_compilation_errors(reason)
        
        # Display formatted errors
        display_compilation_errors(errors, config)
        
        # Return error diagnostics for Mix
        {:error, build_diagnostics(errors)}
    end
  end
  
  defp start_file_watcher(config) do
    # Check if watcher is already running
    case Process.whereis(:haxe_watcher) do
      nil ->
        # Start the watcher process
        {:ok, pid} = HaxeWatcher.start_link(config)
        Process.register(pid, :haxe_watcher)
        Mix.shell().info("Started Haxe file watcher")
      
      _pid ->
        # Watcher already running
        if config[:verbose] do
          Mix.shell().info("Haxe file watcher is already running")
        end
    end
  end
  
  defp manifest_path do
    Mix.Project.manifest_path()
    |> Path.join("compile.haxe")
  end
  
  defp write_manifest(compiled_files) do
    manifest = %{
      version: 1,
      timestamp: System.system_time(:second),
      files: compiled_files,
      config_hash: :erlang.phash2(get_haxe_config())
    }
    
    manifest_path()
    |> Path.dirname()
    |> File.mkdir_p!()
    
    File.write!(manifest_path(), :erlang.term_to_binary(manifest))
  end
  
  defp generated_file?(file_path) do
    # Check if file contains Reflaxe.Elixir generation marker
    case File.read(file_path) do
      {:ok, content} ->
        String.contains?(content, "# Generated from Haxe") ||
        String.contains?(content, "generated from Haxe") ||
        String.contains?(content, "@moduledoc \"\"\"") && String.contains?(content, "module generated from Haxe")
      
      _ ->
        false
    end
  end
  
  defp parse_compilation_errors(reason) when is_binary(reason) do
    # Use HaxeCompiler's error parser
    parsed_errors = HaxeCompiler.parse_haxe_errors(reason)
    
    # If no errors were parsed but we have a reason, create a generic error
    if Enum.empty?(parsed_errors) and String.trim(reason) != "" do
      [%{
        file: nil,
        line: nil,
        column_start: nil,
        column_end: nil,
        type: :compilation_error,
        message: reason,
        raw_line: reason
      }]
    else
      parsed_errors
    end
  end
  
  defp parse_compilation_errors(_), do: []
  
  defp display_compilation_errors([], _config), do: :ok
  
  defp display_compilation_errors(errors, config) do
    Mix.shell().error("")
    Mix.shell().error("== Compilation error in Haxe files ==")
    
    Enum.each(errors, fn error ->
      display_single_error(error, config)
    end)
    
    Mix.shell().error("")
    Mix.shell().info("Hint: Run 'mix haxe.errors' for detailed error analysis")
    Mix.shell().info("      Run 'mix haxe.errors --json' for LLM-friendly format")
  end
  
  defp display_single_error(error, config) do
    location = format_error_location(error)
    
    # Color-coded output based on error type
    case error[:type] do
      :warning ->
        Mix.shell().info("#{location} warning: #{error[:message]}")
      
      _ ->
        Mix.shell().error("#{location} #{error[:error_type] || "error"}: #{error[:message]}")
    end
    
    # Show code context if verbose
    if config[:verbose] && error[:file] && error[:line] do
      show_code_context(error[:file], error[:line], error[:column_start], error[:column_end])
    end
  end
  
  defp format_error_location(error) do
    if error[:file] do
      if error[:line] do
        if error[:column_start] do
          "#{error[:file]}:#{error[:line]}:#{error[:column_start]}"
        else
          "#{error[:file]}:#{error[:line]}"
        end
      else
        "#{error[:file]}"
      end
    else
      ""
    end
  end
  
  defp show_code_context(file, line, col_start, col_end) do
    if File.exists?(file) do
      lines = File.read!(file) |> String.split("\n")
      
      # Show 2 lines before and after for context
      start_line = max(1, line - 2)
      end_line = min(length(lines), line + 2)
      
      Enum.each(start_line..end_line, fn n ->
        line_content = Enum.at(lines, n - 1, "")
        line_prefix = if n == line, do: " > ", else: "   "
        
        Mix.shell().info("#{line_prefix}#{String.pad_leading(to_string(n), 4)} | #{line_content}")
        
        # Show column indicator for the error line
        if n == line && col_start do
          indicator = String.duplicate(" ", col_start + 9) <> 
                     String.duplicate("^", max(1, (col_end || col_start) - col_start + 1))
          Mix.shell().info(indicator)
        end
      end)
    end
  end
  
  defp get_compilation_diagnostics do
    # Get any warnings from the last compilation
    HaxeCompiler.get_compilation_errors(:map)
    |> Enum.filter(fn error -> error[:type] == :warning end)
    |> Enum.map(&build_diagnostic/1)
  end
  
  defp build_diagnostics(errors) do
    Enum.map(errors, &build_diagnostic/1)
  end
  
  defp build_diagnostic(error) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "haxe",
      file: error[:file],
      position: {error[:line] || 0, error[:column_start] || 0},
      message: error[:message] || "",
      severity: diagnostic_severity(error[:type]),
      details: error
    }
  end
  
  defp diagnostic_severity(:warning), do: :warning
  defp diagnostic_severity(_), do: :error
end
