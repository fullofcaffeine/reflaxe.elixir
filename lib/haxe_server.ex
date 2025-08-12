defmodule HaxeServer do
  @moduledoc """
  GenServer for managing the Haxe compilation server (--wait mode).
  
  This module handles starting, stopping, and communicating with the Haxe compiler
  server for incremental compilation. The server uses Haxe's `--wait` mode to
  provide fast incremental builds by caching parsed files and typed modules.
  
  ## Usage
  
      # Start the server
      {:ok, pid} = HaxeServer.start_link([])
      
      # Check if server is running
      HaxeServer.running?()
      
      # Compile using server
      {:ok, result} = HaxeServer.compile(["build.hxml"])
      
      # Stop the server  
      HaxeServer.stop()
  
  ## Configuration
  
  The server can be configured with:
  - `:port` - Port for Haxe server (default: 6000)
  - `:timeout` - Compilation timeout in ms (default: 30000)
  - `:haxe_cmd` - Haxe command to use (default: "npx haxe")
  """
  
  use GenServer
  require Logger

  @default_port 6000
  @default_timeout 30_000
  
  # Don't set a default here, will determine at runtime
  defp default_haxe_cmd() do
    # Find the project's lix-managed haxe if available
    project_root = find_project_root()
    project_haxe = Path.join([project_root, "node_modules", ".bin", "haxe"])
    
    if File.exists?(project_haxe) do
      project_haxe
    else
      "npx haxe"
    end
  end

  # Client API

  @doc """
  Starts the HaxeServer GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if the Haxe server is currently running.
  """
  def running?() do
    try do
      case GenServer.call(__MODULE__, :status, 5000) do
        {:ok, :running} -> true
        _ -> false
      end
    catch
      :exit, _ -> false
    end
  end

  @doc """
  Compiles Haxe code using the server.
  
  ## Parameters
  - `args` - List of arguments to pass to Haxe compiler
  - `opts` - Compilation options (timeout, etc.)
  
  ## Returns
  - `{:ok, output}` - Compilation successful
  - `{:error, reason}` - Compilation failed
  """
  def compile(args, opts \\ []) when is_list(args) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    GenServer.call(__MODULE__, {:compile, args}, timeout)
  end

  @doc """
  Stops the Haxe server gracefully.
  """
  def stop() do
    GenServer.stop(__MODULE__, :normal)
  end

  @doc """
  Gets the current server status and statistics.
  """
  def status() do
    GenServer.call(__MODULE__, :status)
  end

  # Server Implementation

  @impl GenServer
  def init(opts) do
    port = Keyword.get(opts, :port, @default_port)
    haxe_cmd = Keyword.get(opts, :haxe_cmd, default_haxe_cmd())
    
    # Parse the haxe command if it's a string
    {cmd, args} = case haxe_cmd do
      {cmd, args} when is_binary(cmd) and is_list(args) -> {cmd, args}
      cmd when is_binary(cmd) -> 
        parts = String.split(cmd, " ")
        {hd(parts), tl(parts)}
    end
    
    state = %{
      port: port,
      haxe_cmd: cmd,
      haxe_args: args,
      server_pid: nil,
      status: :stopped,
      compile_count: 0,
      last_compile: nil
    }
    
    # Start server asynchronously
    send(self(), :start_server)
    
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start_server, state) do
    case start_haxe_server(state) do
      {:ok, pid} -> 
        Logger.info("Haxe server started on port #{state.port}")
        {:noreply, %{state | server_pid: pid, status: :running}}
      
      {:error, reason} ->
        Logger.error("Failed to start Haxe server: #{reason}")
        # Retry in 5 seconds
        Process.send_after(self(), :start_server, 5000)
        {:noreply, %{state | status: :error}}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{server_pid: pid} = state) do
    Logger.warning("Haxe server process died: #{inspect(reason)}")
    # Restart server automatically
    send(self(), :start_server)
    {:noreply, %{state | server_pid: nil, status: :restarting}}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Ignore other process deaths
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    response = case state.status do
      :running -> {:ok, :running}
      :stopped -> {:error, :stopped}
      :restarting -> {:error, :restarting}
      :error -> {:error, :failed_to_start}
    end
    
    stats = %{
      status: state.status,
      port: state.port,
      compile_count: state.compile_count,
      last_compile: state.last_compile
    }
    
    {:reply, {response, stats}, state}
  end

  @impl GenServer
  def handle_call({:compile, args}, _from, %{status: :running} = state) do
    result = compile_with_server(args, state)
    
    new_state = %{state | 
      compile_count: state.compile_count + 1,
      last_compile: DateTime.utc_now()
    }
    
    {:reply, result, new_state}
  end

  @impl GenServer
  def handle_call({:compile, _args}, _from, state) do
    {:reply, {:error, "Haxe server not running (status: #{state.status})"}, state}
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.info("HaxeServer terminating: #{inspect(reason)}")
    stop_haxe_server(state)
    :ok
  end

  # Private Functions

  defp start_haxe_server(state) do
    cmd_args = state.haxe_args ++ ["--wait", to_string(state.port)]
    
    case System.cmd(state.haxe_cmd, cmd_args, stderr_to_stdout: true) do
      {_output, 0} ->
        # Server started successfully, but we need to get the PID
        # For now, we'll use a placeholder - in real implementation,
        # we'd need to track the server process properly
        {:ok, :server_started}
      
      {output, exit_code} ->
        {:error, "Exit code #{exit_code}: #{output}"}
    end
  rescue
    error ->
      {:error, "Failed to execute haxe command: #{Exception.message(error)}"}
  end

  defp stop_haxe_server(%{server_pid: nil}), do: :ok
  defp stop_haxe_server(_state) do
    # Send shutdown signal to Haxe server
    # This would normally involve sending a specific command to the server
    :ok
  end

  defp compile_with_server(args, state) do
    # Connect to the running Haxe server and send compilation request
    connect_args = state.haxe_args ++ ["--connect", to_string(state.port)] ++ args
    
    case System.cmd(state.haxe_cmd, connect_args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}
      
      {output, exit_code} ->
        # Parse and store structured error information from server compilation
        structured_errors = HaxeCompiler.parse_haxe_errors(output)
        HaxeCompiler.store_compilation_errors(structured_errors)
        
        {:error, "Compilation failed (exit #{exit_code}): #{output}"}
    end
  rescue
    error ->
      {:error, "Failed to connect to Haxe server: #{Exception.message(error)}"}
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