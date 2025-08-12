defmodule HaxeWatcher do
  @moduledoc """
  GenServer for watching Haxe source files and triggering incremental compilation.
  
  This module uses FileSystem to monitor .hx files for changes (creation, modification,
  deletion) and automatically triggers compilation through HaxeServer when changes
  are detected. It supports configurable watch directories and debouncing to prevent
  excessive compilation triggers.
  
  ## Usage
  
      # Start with default configuration
      {:ok, pid} = HaxeWatcher.start_link([])
      
      # Start with custom directories to watch
      {:ok, pid} = HaxeWatcher.start_link([dirs: ["src_haxe", "lib_haxe"]])
      
      # Get current watching status
      HaxeWatcher.status()
      
      # Manually trigger compilation
      HaxeWatcher.trigger_compilation()
      
      # Stop watching
      HaxeWatcher.stop()
  
  ## Configuration
  
  - `:dirs` - List of directories to watch (default: ["src_haxe"])
  - `:patterns` - List of file patterns to watch (default: ["**/*.hx"])  
  - `:debounce_ms` - Debounce period in milliseconds (default: 100)
  - `:auto_compile` - Whether to automatically trigger compilation (default: true)
  """
  
  use GenServer
  require Logger
  
  @default_dirs ["src_haxe"]
  @default_patterns ["**/*.hx"]
  @default_debounce_ms 100
  @default_auto_compile true
  @default_build_file "build.hxml"

  # Client API

  @doc """
  Starts the HaxeWatcher GenServer.
  
  ## Options
  - `:dirs` - Directories to watch for Haxe files
  - `:patterns` - File patterns to match  
  - `:debounce_ms` - Debounce period to prevent excessive compilation
  - `:auto_compile` - Whether to auto-compile on file changes
  - `:build_file` - Path to the build.hxml file (default: "build.hxml")
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current watcher status and statistics.
  """
  def status() do
    GenServer.call(__MODULE__, :status)
  end

  @doc """
  Manually triggers a compilation.
  """
  def trigger_compilation() do
    GenServer.cast(__MODULE__, :trigger_compilation)
  end

  @doc """
  Adds a directory to the watch list.
  """
  def add_watch_dir(dir) when is_binary(dir) do
    GenServer.cast(__MODULE__, {:add_watch_dir, dir})
  end

  @doc """
  Removes a directory from the watch list.
  """
  def remove_watch_dir(dir) when is_binary(dir) do
    GenServer.cast(__MODULE__, {:remove_watch_dir, dir})
  end

  @doc """
  Stops the file watcher gracefully.
  """
  def stop() do
    GenServer.stop(__MODULE__, :normal)
  end

  # Server Implementation

  @impl GenServer
  def init(opts) do
    dirs = Keyword.get(opts, :dirs, @default_dirs)
    patterns = Keyword.get(opts, :patterns, @default_patterns)
    debounce_ms = Keyword.get(opts, :debounce_ms, @default_debounce_ms)
    auto_compile = Keyword.get(opts, :auto_compile, @default_auto_compile)
    build_file = Keyword.get(opts, :build_file, @default_build_file)
    
    state = %{
      dirs: dirs,
      patterns: patterns,
      debounce_ms: debounce_ms,
      auto_compile: auto_compile,
      build_file: build_file,
      watcher_pid: nil,
      debounce_timer: nil,
      file_count: 0,
      last_change: nil,
      compilation_count: 0,
      last_compilation: nil
    }
    
    # Start file watching asynchronously
    send(self(), :start_watching)
    
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start_watching, state) do
    case start_file_watching(state) do
      {:ok, watcher_pid} ->
        Logger.info("HaxeWatcher started monitoring #{length(state.dirs)} directory(ies)")
        file_count = count_haxe_files(state)
        {:noreply, %{state | watcher_pid: watcher_pid, file_count: file_count}}
      
      {:error, reason} ->
        Logger.error("Failed to start file watching: #{inspect(reason)}")
        # Retry in 5 seconds
        Process.send_after(self(), :start_watching, 5000)
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid} = state) do
    if haxe_file?(path, state.patterns) do
      Logger.debug("Haxe file event: #{path} - #{inspect(events)}")
      handle_file_change(events, path, state)
    else
      {:noreply, state}
    end
  end

  @impl GenServer  
  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    Logger.info("File watcher stopped")
    {:noreply, %{state | watcher_pid: nil}}
  end

  @impl GenServer
  def handle_info(:trigger_debounced_compilation, state) do
    Logger.debug("Received :trigger_debounced_compilation, auto_compile: #{state.auto_compile}")
    if state.auto_compile do
      trigger_compilation_now(state)
    else
      {:noreply, %{state | debounce_timer: nil}}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{watcher_pid: pid} = state) do
    Logger.warning("File watcher process died: #{inspect(reason)}")
    # Restart file watching
    send(self(), :start_watching)
    {:noreply, %{state | watcher_pid: nil}}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Ignore other process deaths
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    watching = not is_nil(state.watcher_pid) and Process.alive?(state.watcher_pid)
    
    status = %{
      watching: watching,
      dirs: state.dirs,
      patterns: state.patterns,
      auto_compile: state.auto_compile,
      debounce_ms: state.debounce_ms,
      build_file: state.build_file,
      file_count: count_haxe_files(state),
      last_change: state.last_change,
      compilation_count: state.compilation_count,
      last_compilation: state.last_compilation
    }
    
    {:reply, status, state}
  end

  @impl GenServer
  def handle_cast(:trigger_compilation, state) do
    trigger_compilation_now(state)
  end

  @impl GenServer
  def handle_cast({:add_watch_dir, dir}, state) do
    if File.exists?(dir) and dir not in state.dirs do
      new_dirs = [dir | state.dirs]
      Logger.info("Added watch directory: #{dir}")
      
      # Restart watching to include new directory
      if state.watcher_pid do
        GenServer.stop(state.watcher_pid)
      end
      send(self(), :start_watching)
      
      {:noreply, %{state | dirs: new_dirs, watcher_pid: nil}}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:remove_watch_dir, dir}, state) do
    if dir in state.dirs do
      new_dirs = List.delete(state.dirs, dir)
      Logger.info("Removed watch directory: #{dir}")
      
      # Restart watching without removed directory
      if state.watcher_pid do
        GenServer.stop(state.watcher_pid)
      end
      send(self(), :start_watching)
      
      {:noreply, %{state | dirs: new_dirs, watcher_pid: nil}}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.info("HaxeWatcher terminating: #{inspect(reason)}")
    
    if state.watcher_pid do
      GenServer.stop(state.watcher_pid)
    end
    
    if state.debounce_timer do
      Process.cancel_timer(state.debounce_timer)
    end
    
    :ok
  end

  # Private Functions

  defp start_file_watching(state) do
    existing_dirs = Enum.filter(state.dirs, &File.exists?/1)
    
    if Enum.empty?(existing_dirs) do
      Logger.warning("No valid directories to watch: #{inspect(state.dirs)}")
      {:error, :no_valid_directories}
    else
      # Check if FileSystem module is available
      if Code.ensure_loaded?(FileSystem) do
        case FileSystem.start_link(dirs: existing_dirs) do
          {:ok, pid} ->
            FileSystem.subscribe(pid)
            {:ok, pid}
            
          {:error, reason} ->
            {:error, reason}
        end
      else
        Logger.warning("FileSystem module not available, file watching disabled")
        {:error, :filesystem_not_available}
      end
    end
  end

  defp handle_file_change(events, path, state) do
    Logger.debug("handle_file_change called, debounce_ms: #{state.debounce_ms}, auto_compile: #{state.auto_compile}")
    
    # Update last change time
    new_state = %{state | 
      last_change: DateTime.utc_now(),
      file_count: count_haxe_files(state)
    }
    
    # Cancel existing debounce timer
    if state.debounce_timer do
      Logger.debug("Cancelling existing timer")
      Process.cancel_timer(state.debounce_timer)
    end
    
    # Set new debounce timer
    Logger.debug("Setting new debounce timer for #{state.debounce_ms}ms")
    timer = Process.send_after(self(), :trigger_debounced_compilation, state.debounce_ms)
    
    # Log the change
    event_description = events
    |> Enum.map(&event_to_string/1)
    |> Enum.join(", ")
    
    Logger.debug("Haxe file #{event_description}: #{Path.relative_to_cwd(path)}")
    
    {:noreply, %{new_state | debounce_timer: timer}}
  end

  defp trigger_compilation_now(state) do
    Logger.info("Triggering Haxe compilation...")
    
    # Find the build file in the watched directories
    build_file_path = find_build_file(state)
    
    # Attempt compilation through HaxeServer if available
    result = case HaxeServer.running?() do
      true ->
        # Use incremental compilation through server
        HaxeServer.compile([build_file_path])
        
      false ->
        # Fall back to direct compilation
        # Change to the directory containing the build file so relative paths work correctly
        build_dir = Path.dirname(build_file_path)
        build_file_name = Path.basename(build_file_path)
        
        compile_opts = case build_dir do
          "." -> [stderr_to_stdout: true]
          dir -> [cd: dir, stderr_to_stdout: true]
        end
        
        # Use just the filename if we're changing directory
        final_build_file = if Keyword.has_key?(compile_opts, :cd) do
          build_file_name
        else
          build_file_path
        end
        
        # Use the project's lix-managed haxe if available
        {haxe_cmd, haxe_args} = get_haxe_command()
        final_args = haxe_args ++ [final_build_file]
        
        case System.cmd(haxe_cmd, final_args, compile_opts) do
          {output, 0} ->
            {:ok, output}
          {output, exit_code} ->
            {:error, "Compilation failed (exit #{exit_code}): #{output}"}
        end
    end
    
    # Log compilation result
    case result do
      {:ok, _output} ->
        Logger.info("✅ Haxe compilation successful")
        
      {:error, error} ->
        Logger.error("❌ Haxe compilation failed: #{error}")
    end
    
    new_state = %{state | 
      compilation_count: state.compilation_count + 1,
      last_compilation: DateTime.utc_now(),
      debounce_timer: nil
    }
    
    {:noreply, new_state}
  end

  defp haxe_file?(path, patterns) do
    # Guard against nil path
    case path do
      nil -> false
      _ ->
        filename = Path.basename(path)
        
        Enum.any?(patterns, fn pattern ->
          # Simple pattern matching - could be enhanced with proper glob matching
          case pattern do
            "**/*.hx" -> String.ends_with?(filename, ".hx")
            "*.hx" -> String.ends_with?(filename, ".hx")
            ^filename -> true
            _ -> false
          end
        end)
    end
  end

  defp count_haxe_files(state) do
    state.dirs
    |> Enum.filter(&File.exists?/1)
    |> Enum.flat_map(fn dir ->
      state.patterns
      |> Enum.flat_map(fn pattern ->
        Path.join(dir, pattern)
        |> Path.wildcard()
      end)
    end)
    |> Enum.uniq()
    |> length()
  end
  
  defp find_build_file(state) do
    # First, check if build_file is an absolute path
    if Path.type(state.build_file) == :absolute and File.exists?(state.build_file) do
      state.build_file
    else
      # Look for the build file in watched directories
      build_file_name = Path.basename(state.build_file)
      
      found_path = state.dirs
      |> Enum.filter(&File.exists?/1)
      |> Enum.map(fn dir -> Path.join(dir, build_file_name) end)
      |> Enum.find(&File.exists?/1)
      
      # Fall back to the original path if not found in watched dirs
      found_path || state.build_file
    end
  end

  defp event_to_string(:created), do: "created"
  defp event_to_string(:modified), do: "modified"  
  defp event_to_string(:removed), do: "removed"
  defp event_to_string(:renamed), do: "renamed"
  defp event_to_string(other), do: to_string(other)
  
  defp get_haxe_command() do
    # First try to find the project's lix-managed haxe binary
    # This ensures we use the correct version even when running from temp directories
    project_root = find_project_root()
    project_haxe = Path.join([project_root, "node_modules", ".bin", "haxe"])
    
    cond do
      # Check for project's lix-managed haxe first
      File.exists?(project_haxe) ->
        {project_haxe, []}
      
      # Fallback to npx haxe
      System.find_executable("npx") != nil ->
        {"npx", ["haxe"]}
      
      # Check if haxe is directly available
      System.find_executable("haxe") != nil ->
        {"haxe", []}
        
      true ->
        # Final fallback - will likely fail but provides clear error
        {"haxe", []}
    end
  end
  
  defp find_project_root() do
    # Try to find the project root by looking for mix.exs or package.json
    # Start from current directory and walk up
    find_project_root_from(File.cwd!())
  end
  
  defp find_project_root_from(dir) do
    cond do
      # Found project markers
      File.exists?(Path.join(dir, "mix.exs")) or 
      File.exists?(Path.join(dir, "package.json")) ->
        dir
      
      # Reached root directory
      dir == "/" or dir == Path.dirname(dir) ->
        # Default to current directory if we can't find project root
        File.cwd!()
      
      # Keep searching up
      true ->
        find_project_root_from(Path.dirname(dir))
    end
  end
end