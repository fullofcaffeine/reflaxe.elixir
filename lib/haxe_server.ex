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
  - `:port` - Port for Haxe server (default: 6116; tests pick a free port)
  - `:timeout` - Compilation timeout in ms (default: 30000)
  - `:haxe_cmd` - Haxe command to use (default: auto-detected)
  """
  
  use GenServer
  require Logger

  # Align the default with QA sentinel and avoid clashes with common editor defaults
  @default_port 6116
  @default_timeout 30_000
  
  # Don't set a default here, will determine at runtime
  defp default_haxe_cmd() do
    project_root = find_project_root()
    project_haxe = Path.join([project_root, "node_modules", ".bin", "haxe"])
    project_lix = Path.join([project_root, "node_modules", ".bin", "lix"])

    cond do
      # Prefer a project-local haxe shim if present.
      File.exists?(project_haxe) ->
        {project_haxe, []}

      # Prefer an already-installed haxe on PATH to avoid implicit npm installs.
      (haxe_exe = System.find_executable("haxe")) != nil ->
        {haxe_exe, []}

      # If lix is installed locally, use it to run the configured haxe toolchain.
      File.exists?(project_lix) ->
        {project_lix, ["run", "haxe"]}

      # Fall back to any globally installed lix.
      (lix_exe = System.find_executable("lix")) != nil ->
        {lix_exe, ["run", "haxe"]}

      # Final fallback: try "haxe" and let startup fail fast if unavailable.
      true ->
        {"haxe", []}
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
    GenServer.stop(__MODULE__, :normal, 5000)
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
    # Determine port preference order:
    # 1) explicit opts
    # 2) HAXE_SERVER_PORT env
    # 3) test env: find a free port to avoid conflicts
    # 4) default (@default_port)
    env_port = System.get_env("HAXE_SERVER_PORT")
    port =
      cond do
        Keyword.has_key?(opts, :port) -> Keyword.fetch!(opts, :port)
        env_port != nil -> String.to_integer(env_port)
        Mix.env() == :test -> find_available_port()
        true -> @default_port
      end
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
    
    # If HAXE_NO_SERVER=1, do not attempt to start a server; callers will fall back to direct haxe.
    if System.get_env("HAXE_NO_SERVER") == "1" do
      {:ok, state}
    else
      # Start and manage our own `haxe --wait` server instance.
      #
      # We intentionally do NOT "reuse" an already-running server on the same port:
      # - It might be a different Haxe toolchain/version than this project expects (lix vs global).
      # - We can't reliably stop/monitor an external process, which leads to stale state and port
      #   collisions in tests/dev.
      #
      # If the configured port is already bound (EADDRINUSE), we transparently relocate to a free port.
      send(self(), :start_server)
      {:ok, state}
    end
  end

  @impl GenServer
  def handle_info(:start_server, state) do
    case start_haxe_server(state) do
      {:ok, pid} -> 
        Logger.debug("Haxe server started on port #{state.port}")
        {:noreply, %{state | server_pid: pid, status: :running}}
      
      {:error, reason} ->
        # Try an immediate relocation to a free port (transparent to the user)
        Logger.debug("Haxe server failed on #{state.port} (#{inspect(reason)}); attempting relocation")
        new_port = find_available_port()
        relocated = %{state | port: new_port}
        case start_haxe_server(relocated) do
          {:ok, pid2} ->
            Logger.debug("Haxe server relocated and started on port #{new_port}")
            {:noreply, %{relocated | server_pid: pid2, status: :running}}
          {:error, reason2} ->
            Logger.warning("Failed to start Haxe server after relocation: #{inspect(reason2)}; will retry")
            Process.send_after(self(), :start_server, 2000)
            {:noreply, %{relocated | status: :error}}
        end
    end
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{server_pid: pid} = state) do
    Logger.debug("Haxe server process died: #{inspect(reason)}; restarting")
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
  def handle_info({port, {:data, data}}, state) when is_port(port) do
    # Log the output from Haxe server for debugging
    Logger.debug("Haxe server output: #{data}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({port, {:exit_status, status}}, state) when is_port(port) do
    Logger.debug("Haxe server exited with status: #{status}; restarting")
    # Restart the server
    send(self(), :start_server)
    {:noreply, %{state | server_pid: nil, status: :restarting}}
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
    # Use Port.open to properly manage the Haxe server process
    cmd = state.haxe_cmd
    args = state.haxe_args ++ ["--wait", to_string(state.port)]
    
    # Generate a unique port for haxeshim's internal server to avoid conflicts
    # when running tests in parallel
    haxeshim_port = if Mix.env() == :test do
      # Use a different range than the wait port to avoid conflicts
      9000 + rem(System.unique_integer([:positive]), 1000)
    else
      8000
    end
    
    # Set environment variable for haxeshim (if it supports it)
    # Also set HAXE_SERVER_PORT for compatibility
    # Port.open requires charlists (Erlang strings) for env variables
    env = [
      {~c"HAXESHIM_SERVER_PORT", to_charlist(haxeshim_port)},
      {~c"HAXE_SERVER_PORT", to_charlist(state.port)}
    ]
    
    try do
      port = Port.open(
        {:spawn_executable, System.find_executable(cmd) || cmd},
        [:binary, :exit_status, :stderr_to_stdout, {:args, args}, {:env, env}]
      )
      
      # Give the server a moment to start
      Process.sleep(500)
      
      # Check if port is still alive
      if Port.info(port) do
        {:ok, port}
      else
        {:error, "Haxe server process exited immediately"}
      end
    rescue
      error ->
        {:error, "Failed to start Haxe server: #{Exception.message(error)}"}
    end
  end

  defp stop_haxe_server(%{server_pid: nil}), do: :ok
  defp stop_haxe_server(%{server_pid: port}) when is_port(port) do
    # Close the port to stop the Haxe server
    Port.close(port)
    :ok
  end
  defp stop_haxe_server(_state) do
    # No server to stop
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

  defp find_available_port() do
    # Pick from a mid-range that avoids common dev ports (<10k) and OS ephemeral ports (often 49k+).
    # This reduces collisions with both local services and active outbound connections.
    base_port = 15_000 + rem(System.unique_integer([:positive]), 20_000)

    port_available? = fn port ->
      # Haxe (via lix/haxeshim) binds to the IPv6 wildcard (::) by default, typically
      # as a dual-stack socket (v6only=false). Probe with an IPv6 dual-stack listen
      # first, falling back to IPv4 when IPv6 isn't available.
      ipv6_opts = [:binary, packet: :line, active: false, reuseaddr: true, ip: {0, 0, 0, 0, 0, 0, 0, 0}, ipv6_v6only: false]

      case :gen_tcp.listen(port, ipv6_opts) do
        {:ok, socket} ->
          :gen_tcp.close(socket)
          true

        {:error, _} ->
          case :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true]) do
            {:ok, socket} ->
              :gen_tcp.close(socket)
              true

            {:error, _} ->
              false
          end
      end
    end
    
    Enum.reduce_while(0..50, nil, fn offset, _acc ->
      port = base_port + offset
      if port_available?.(port), do: {:halt, port}, else: {:cont, nil}
    end) || 35_000 + :rand.uniform(5_000)  # Better fallback with randomization
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
