defmodule Mix.Tasks.Compile.Haxe do
  @moduledoc """
  Mix compiler task for integrating Haxe compilation with Phoenix build pipeline.
  
  This task compiles Haxe source files to Elixir using the Reflaxe.Elixir compiler,
  enabling seamless integration with Phoenix applications.
  
  ## Configuration
  
  In your `mix.exs`, add `:haxe` to your list of compilers:
  
      def project do
        [compilers: [:haxe] ++ Mix.compilers()]
      end
  
  ## Options
  
    * `--verbose` - Enable verbose output
    * `--force` - Force recompilation of all files
    * `--watch` - Start file watching for automatic recompilation (dev mode only)
    
  ## Example Usage
  
      mix compile.haxe
      mix compile.haxe --verbose
      mix compile.haxe --force
      mix compile.haxe --watch --verbose
  """
  
  use Mix.Task.Compiler

  @shortdoc "Compiles Haxe source files to Elixir"
  @recursive true

  @impl Mix.Task.Compiler
  def run(args) do
    {opts, _} = OptionParser.parse!(args, 
      strict: [verbose: :boolean, force: :boolean, watch: :boolean],
      aliases: [v: :verbose, f: :force, w: :watch]
    )
    
    config = get_compiler_config()
    compile_opts = Keyword.merge(config, opts)
    
    if compile_opts[:verbose] do
      Mix.shell().info("Starting Haxe compilation...")
    end
    
    # Start file watching if requested and in development
    if Keyword.get(compile_opts, :watch, false) and Mix.env() == :dev do
      start_file_watching(compile_opts)
    end
    
    case HaxeCompiler.needs_recompilation?(compile_opts) do
      false ->
        if compile_opts[:verbose] do
          Mix.shell().info("No recompilation needed")
        end
        {:noop, []}
      
      true ->
        # Try to start HaxeServer for incremental compilation
        if Mix.env() == :dev and not HaxeServer.running?() do
          try do
            {:ok, _pid} = HaxeServer.start_link([])
            if compile_opts[:verbose] do
              Mix.shell().info("Started Haxe server for incremental compilation")
            end
          catch
            _, _ -> 
              if compile_opts[:verbose] do
                Mix.shell().info("Could not start Haxe server, using direct compilation")
              end
          end
        end
        
        case HaxeCompiler.compile(compile_opts) do
          {:ok, []} ->
            if compile_opts[:verbose] do
              Mix.shell().info("No Haxe files found to compile")
            end
            {:noop, []}
          
          {:ok, compiled_files} ->
            Mix.shell().info("Compiled #{length(compiled_files)} Haxe file(s)")
            update_manifest(compiled_files)
            {:ok, compiled_files}
          
          {:error, reason} ->
            Mix.shell().error("Haxe compilation failed: #{reason}")
            {:error, []}
        end
    end
  end
  
  @impl Mix.Task.Compiler
  def manifests do
    [manifest_path()]
  end
  
  @impl Mix.Task.Compiler
  def clean do
    File.rm_rf(manifest_path())
    :ok
  end
  
  defp manifest_path do
    Path.join(Mix.Project.manifest_path(), "compile.haxe")
  end
  
  defp get_compiler_config do
    project_config = Mix.Project.config()
    
    # Default configuration
    defaults = [
      hxml_file: "build.hxml",
      source_dir: "src_haxe", 
      target_dir: "lib",
      verbose: false,
      force: false
    ]
    
    # Merge with project-specific config if available
    haxe_config = Keyword.get(project_config, :haxe_compiler, [])
    Keyword.merge(defaults, haxe_config)
  end
  
  defp start_file_watching(opts) do
    source_dir = opts[:source_dir] || "src_haxe"
    
    if File.exists?(source_dir) do
      try do
        if not GenServer.whereis(HaxeWatcher) do
          {:ok, _pid} = HaxeWatcher.start_link([
            dirs: [source_dir],
            auto_compile: true,
            debounce_ms: 100
          ])
          
          Mix.shell().info("🔍 Started file watching on #{source_dir}")
        else
          Mix.shell().info("🔍 File watching already active")
        end
      catch
        _, error -> 
          Mix.shell().info("⚠️  Could not start file watching: #{inspect(error)}")
      end
    else
      if opts[:verbose] do
        Mix.shell().info("⚠️  Source directory #{source_dir} not found, skipping file watching")
      end
    end
  end
  
  defp update_manifest(compiled_files) do
    manifest_path = manifest_path()
    File.mkdir_p!(Path.dirname(manifest_path))
    
    manifest_data = %{
      compiled_files: compiled_files,
      timestamp: System.system_time(:second)
    }
    
    File.write!(manifest_path, :erlang.term_to_binary(manifest_data))
  end
end