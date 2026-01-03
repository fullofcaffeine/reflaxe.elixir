defmodule Mix.Tasks.Haxe.Watch do
  @moduledoc """
  Watches Haxe source files and automatically recompiles on changes.
  
  This task provides manual control over the file watcher, useful for:
  - Development workflows that need explicit watching
  - Debugging compilation issues
  - Running outside of Mix's compile pipeline
  
  ## Usage
  
      mix haxe.watch              # Start watching with defaults
      mix haxe.watch --verbose     # Show detailed output
      mix haxe.watch --once        # Compile once and exit
      mix haxe.watch --dirs src,lib # Watch specific directories
      mix haxe.watch --hxml build.hxml # Use a specific HXML file
  
  ## Options
  
    * `--verbose` - Show detailed compilation output
    * `--once` - Compile once and exit (no watching)
    * `--dirs` - Comma-separated list of directories to watch
    * `--debounce` - Debounce period in milliseconds (default: 100)
    * `--hxml` - Path to build.hxml file (default: "build.hxml")
  
  ## Configuration
  
  You can also configure defaults in `mix.exs`:
  
      def project do
        [
          haxe: [
            watch_dirs: ["src", "test"],
            debounce_ms: 200,
            hxml_file: "build.hxml"
          ]
        ]
      end
  """
  
  use Mix.Task
  
  @shortdoc "Watches and recompiles Haxe files on changes"
  
  @impl Mix.Task
  def run(args) do
    # Parse command line options
    {opts, _, _} = OptionParser.parse(args,
      switches: [
        verbose: :boolean,
        once: :boolean,
        dirs: :string,
        debounce: :integer,
        hxml: :string
      ]
    )
    
    # Get configuration from mix.exs
    config = get_watch_config(opts)
    
    # Ensure code is compiled and loaded, but don't start the full application tree.
    Mix.Task.run("app.start", ["--no-start"])
    
    if opts[:once] do
      # Just compile once and exit
      compile_once(config)
    else
      # Start watching
      start_watching(config)
    end
  end
  
  defp get_watch_config(opts) do
    # Start with project config
    project_config = Mix.Project.config()[:haxe] || []

    # Parse directories from command line
    source_dir = Keyword.get(project_config, :source_dir, "src_haxe")

    # HaxeCompiler expects :hxml_file, while HaxeWatcher expects :build_file.
    # Keep them in sync so the initial compile and subsequent watch recompiles
    # use the same build configuration.
    hxml_file = opts[:hxml] || Keyword.get(project_config, :hxml_file, "build.hxml")

    dirs =
      case opts[:dirs] do
        nil ->
          # Prefer explicit watch_dirs; otherwise default to the project source_dir.
          Keyword.get(project_config, :watch_dirs, [source_dir])

        dirs_string ->
          String.split(dirs_string, ",") |> Enum.map(&String.trim/1)
      end

    # Build final configuration
    [
      dirs: dirs,
      debounce_ms: opts[:debounce] || Keyword.get(project_config, :debounce_ms, 100),
      # HaxeWatcher expects :build_file; HaxeCompiler expects :hxml_file
      build_file: hxml_file,
      hxml_file: hxml_file,
      verbose: opts[:verbose] || false,
      auto_compile: true,
      source_dir: source_dir,
      target_dir: Keyword.get(project_config, :target_dir, "lib")
    ]
  end
  
  defp compile_once(config) do
    Mix.shell().info("Compiling Haxe files...")
    
    case HaxeCompiler.compile(config) do
      {:ok, files} ->
        Mix.shell().info("✓ Compiled #{length(files)} file(s)")
        
      {:error, reason} ->
        Mix.shell().error("✗ Compilation failed:")
        Mix.shell().error(reason)
        exit({:shutdown, 1})
    end
  end
  
  defp start_watching(config) do
    Mix.shell().info("Starting Haxe file watcher...")
    Mix.shell().info("Watching directories: #{inspect(config[:dirs])}")
    Mix.shell().info("Press Ctrl+C to stop")
    Mix.shell().info("")
    
    # Initial compilation
    compile_once(config)
    
    # Start the watcher
    case HaxeWatcher.start_link(config) do
      {:ok, pid} ->
        # Monitor the watcher process
        ref = Process.monitor(pid)
        
        # Register for compilation events
        :ok = register_compilation_callbacks(config)
        
        # Keep the task running
        receive do
          {:DOWN, ^ref, :process, ^pid, reason} ->
            Mix.shell().error("Watcher stopped: #{inspect(reason)}")
            exit({:shutdown, 1})
        end
        
      {:error, {:already_started, _pid}} ->
        Mix.shell().info("Watcher is already running")
        
        # Just wait indefinitely
        receive do
          :never -> :ok
        end
        
      {:error, reason} ->
        Mix.shell().error("Failed to start watcher: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end
  
  defp register_compilation_callbacks(config) do
    # Register a callback to show compilation results
    spawn_link(fn ->
      monitor_compilation_loop(config)
    end)
    
    :ok
  end
  
  defp monitor_compilation_loop(config) do
    receive do
      {:compilation_started, files} ->
        if config[:verbose] do
          Mix.shell().info("→ Recompiling #{length(files)} changed file(s)...")
        else
          Mix.shell().info("→ Recompiling...")
        end
        
      {:compilation_finished, {:ok, compiled_files}} ->
        Mix.shell().info("✓ Compiled successfully (#{length(compiled_files)} files)")
        
      {:compilation_finished, {:error, reason}} ->
        Mix.shell().error("✗ Compilation failed:")
        display_formatted_errors(reason, config)
        
      _ ->
        :ok
    end
    
    # Continue monitoring
    monitor_compilation_loop(config)
  end
  
  defp display_formatted_errors(reason, config) when is_binary(reason) do
    errors = HaxeCompiler.parse_haxe_errors(reason)
    
    if Enum.empty?(errors) do
      Mix.shell().error(reason)
    else
      Enum.each(errors, fn error ->
        display_error(error, config)
      end)
      
      Mix.shell().info("\nHint: Run 'mix haxe.errors --json' for detailed error information")
    end
  end
  
  defp display_formatted_errors(reason, _config) do
    Mix.shell().error(inspect(reason))
  end
  
  defp display_error(error, config) do
    location = format_location(error)
    message = error[:message] || "Unknown error"
    
    case error[:type] do
      :warning ->
        Mix.shell().info("  ⚠ #{location} #{message}")
        
      _ ->
        error_type = error[:error_type] || "Error"
        Mix.shell().error("  ✗ #{location} #{error_type}: #{message}")
    end
    
    # Show code context in verbose mode
    if config[:verbose] && error[:file] && File.exists?(error[:file]) do
      show_code_snippet(error)
    end
  end
  
  defp format_location(error) do
    parts = [
      error[:file],
      error[:line] && ":#{error[:line]}",
      error[:column_start] && ":#{error[:column_start]}"
    ]
    |> Enum.filter(& &1)
    |> Enum.join("")
    
    if parts == "" do
      "[unknown location]"
    else
      parts
    end
  end
  
  defp show_code_snippet(error) do
    file = error[:file]
    line_num = error[:line]
    
    if file && line_num do
      lines = File.read!(file) |> String.split("\n")
      
      # Show the error line with context
      if line_num > 0 && line_num <= length(lines) do
        line_content = Enum.at(lines, line_num - 1)
        Mix.shell().info("    │ #{line_content}")
        
        # Show column indicator if available
        if error[:column_start] do
          indicator = String.duplicate(" ", 5 + error[:column_start]) <> "^"
          Mix.shell().info(indicator)
        end
      end
    end
  end
end
