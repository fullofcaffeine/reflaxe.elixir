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
  @cookie_dir ".reflaxe_elixir"
  @cookie_file "haxe_server.json"
  @cookie_version 1

  # By default we do NOT attach to an externally-started Haxe --wait server even if it
  # responds to `--connect -version`. Sharing a server across unrelated build contexts can
  # corrupt the incremental cache and trigger internal compiler crashes (e.g. OCaml
  # `globals.ml: Assertion failed`). Opt in explicitly if you know the server is safe to share.
  @allow_external_attach_env "HAXE_SERVER_ALLOW_ATTACH"

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
        {{:ok, :running}, _stats} -> true
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
    _ = ensure_haxeshim_server_port_env()

    project_root = find_project_root()
    cookie_path = cookie_path(project_root)

    # Determine port preference order:
    # 1) explicit opts
    # 2) HAXE_SERVER_PORT env
    # 3) test env: find a free port to avoid conflicts
    # 4) default (@default_port)
    env_port = System.get_env("HAXE_SERVER_PORT")
    haxe_cmd = Keyword.get(opts, :haxe_cmd, default_haxe_cmd())

    # Parse the haxe command if it's a string
    {cmd, args} =
      case haxe_cmd do
        {cmd, args} when is_binary(cmd) and is_list(args) ->
          {cmd, args}

        cmd when is_binary(cmd) ->
          parts = String.split(cmd, " ")
          {hd(parts), tl(parts)}
      end

    cache_key = cache_key(project_root, cmd, args)

    port =
      cond do
        Keyword.has_key?(opts, :port) ->
          Keyword.fetch!(opts, :port)

        env_port != nil ->
          String.to_integer(env_port)

        Mix.env() == :test ->
          find_available_port()

        true ->
          case read_cookie(cookie_path) do
            {:ok,
             %{"version" => @cookie_version, "port" => cookie_port, "cache_key" => ^cache_key}}
            when is_integer(cookie_port) and cookie_port > 0 ->
              cookie_port

            _ ->
              @default_port
          end
      end

    state = %{
      port: port,
      haxe_cmd: cmd,
      haxe_args: args,
      project_root: project_root,
      cookie_path: cookie_path,
      cache_key: cache_key,
      server_pid: nil,
      server_os_pid: nil,
      owns_server: false,
      status: :stopped,
      allow_external_attach: allow_external_attach?(),
      compile_count: 0,
      last_compile: nil
    }

    # If HAXE_NO_SERVER=1, do not attempt to start a server; callers will fall back to direct haxe.
    if System.get_env("HAXE_NO_SERVER") == "1" do
      {:ok, state}
    else
      # Start or attach immediately so callers can use the incremental server cache right away.
      #
      # If the configured port is already bound (EADDRINUSE), attempt to attach to an existing
      # compatible server; otherwise relocate to a free port.
      case start_or_attach_server(state) do
        {:ok, started} ->
          {:ok, started}

        {:error, failed} ->
          Process.send_after(self(), :start_server, 2000)
          {:ok, failed}
      end
    end
  end

  @impl GenServer
  def handle_info(:start_server, state) do
    case start_or_attach_server(state) do
      {:ok, started} ->
        {:noreply, started}

      {:error, failed} ->
        Process.send_after(self(), :start_server, 2000)
        {:noreply, failed}
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
    {:noreply, %{state | server_pid: nil, server_os_pid: nil, status: :restarting}}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    response =
      case state.status do
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

    new_state = %{
      state
      | compile_count: state.compile_count + 1,
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
    maybe_remove_cookie(state)
    :ok
  end

  # Private Functions

  defp start_haxe_server(state) do
    # Use Port.open to properly manage the Haxe server process
    cmd = state.haxe_cmd
    args = state.haxe_args ++ ["--wait", to_string(state.port)]

    # Generate a unique port for haxeshim's internal server to avoid collisions in dev/test
    # when multiple Mix VMs (or multiple HaxeServer instances) are running concurrently.
    #
    # Keep it distinct from the Haxe `--wait` port we're binding to.
    haxeshim_port = ensure_haxeshim_server_port_env()

    # Set environment variable for haxeshim (if it supports it)
    # Also set HAXE_SERVER_PORT for compatibility
    # Port.open requires charlists (Erlang strings) for env variables
    env = [
      {~c"HAXESHIM_SERVER_PORT", to_charlist(haxeshim_port)},
      {~c"HAXE_SERVER_PORT", to_charlist(state.port)}
    ]

    try do
      port =
        Port.open(
          {:spawn_executable, System.find_executable(cmd) || cmd},
          [:binary, :exit_status, :stderr_to_stdout, {:args, args}, {:env, env}]
        )

      # Give the server a moment to start.
      #
      # NOTE: `haxe --wait` is a long-lived process. On some platforms/wrappers, closing the
      # Erlang port does not reliably terminate the underlying OS process. We capture the
      # OS PID to ensure we can clean up on stop/restart.
      Process.sleep(500)

      # Check if port is still alive
      if Port.info(port) do
        os_pid =
          case Port.info(port, :os_pid) do
            {:os_pid, pid} when is_integer(pid) -> pid
            _ -> nil
          end

        {:ok, port, os_pid}
      else
        {:error, "Haxe server process exited immediately"}
      end
    rescue
      error ->
        {:error, "Failed to start Haxe server: #{Exception.message(error)}"}
    end
  end

  defp stop_haxe_server(%{server_pid: nil}), do: :ok

  defp stop_haxe_server(%{server_pid: port, server_os_pid: os_pid, owns_server: true})
       when is_port(port) do
    # Best-effort shutdown order:
    # 1) Close the Erlang port.
    # 2) Explicitly terminate the OS process tree (node wrapper + underlying haxe) if still alive.
    #
    # Rationale: On some setups the haxe shim runs as a Node process and spawns a real `haxe`
    # server process. Closing the port does not always kill the child, which leads to leaked
    # `haxe --wait` processes and port churn on subsequent compiles.
    try do
      Port.close(port)
    rescue
      _ -> :ok
    end

    kill_process_tree(os_pid)
    :ok
  end

  defp stop_haxe_server(_state), do: :ok

  defp external_server_compatible?(state) do
    connect_args = state.haxe_args ++ ["--connect", to_string(state.port), "-version"]

    # This check runs when the preferred port is already bound. In common dev flows,
    # that can be a concurrently-starting (but not yet ready) Haxe server. Give it a
    # small bounded grace window to become responsive before relocating.
    timeouts_ms = [200, 500, 1_000, 2_000, 5_000]

    {compatible, last_result} =
      Enum.reduce_while(timeouts_ms, {false, nil}, fn timeout_ms, _acc ->
        result = connect_for_version(connect_args, state, timeout_ms)

        case result do
          {_out, 0} ->
            {:halt, {true, result}}

          {:timeout, _} ->
            {:cont, {false, result}}

          {_out, _exit_code} ->
            {:halt, {false, result}}
        end
      end)

    if not compatible do
      case last_result do
        {:timeout, _} ->
          Logger.debug(
            "Haxe server port #{state.port} is in use but did not respond to --connect -version; relocating"
          )

        {out, exit_code} when is_binary(out) and is_integer(exit_code) ->
          summary =
            out
            |> String.split("\n", trim: false)
            |> Enum.find("", fn line -> String.trim(line) != "" end)
            |> String.trim()
            |> String.slice(0, 200)

          Logger.debug(
            "Haxe server port #{state.port} is in use but is not compatible (exit #{exit_code}): #{summary}"
          )

        _ ->
          Logger.debug(
            "Haxe server port #{state.port} is in use but could not be verified as compatible; relocating"
          )
      end
    end

    compatible
  rescue
    _ -> false
  end

  defp connect_for_version(connect_args, state, timeout_ms) do
    task =
      Task.async(fn ->
        System.cmd(state.haxe_cmd, connect_args, stderr_to_stdout: true)
      end)

    case Task.yield(task, timeout_ms) do
      {:ok, value} ->
        value

      nil ->
        _ = Task.shutdown(task, :brutal_kill)
        {:timeout, 1}
    end
  end

  defp start_or_attach_server(state) do
    if port_available?(state.port) do
      case start_haxe_server(state) do
        {:ok, pid, os_pid} ->
          Logger.debug("Haxe server started on port #{state.port}")

          started = %{
            state
            | server_pid: pid,
              server_os_pid: os_pid,
              owns_server: true,
              status: :running
          }

          _ = write_cookie(started)
          {:ok, started}

        {:error, reason} ->
          Logger.debug(
            "Haxe server failed on #{state.port} (#{inspect(reason)}); attempting relocation"
          )

          new_port = find_available_port()
          relocated = %{state | port: new_port}

          case start_haxe_server(relocated) do
            {:ok, pid2, os_pid2} ->
              Logger.debug("Haxe server relocated and started on port #{new_port}")

              started = %{
                relocated
                | server_pid: pid2,
                  server_os_pid: os_pid2,
                  owns_server: true,
                  status: :running
              }

              _ = write_cookie(started)
              {:ok, started}

            {:error, reason2} ->
              Logger.warning(
                "Failed to start Haxe server after relocation: #{inspect(reason2)}; will retry"
              )

              {:error,
               %{
                 relocated
                 | server_pid: nil,
                   server_os_pid: nil,
                   owns_server: false,
                   status: :error
               }}
          end
      end
    else
      cond do
        attach_to_cookie_server?(state) and external_server_compatible?(state) ->
          Logger.debug(
            "Haxe server port #{state.port} is in use; attaching to prior server (cookie match)"
          )

          _ = write_cookie(%{state | owns_server: false, status: :running})

          {:ok,
           %{state | server_pid: nil, server_os_pid: nil, owns_server: false, status: :running}}

        state.allow_external_attach and external_server_compatible?(state) ->
          Logger.debug("Haxe server port #{state.port} is in use; attaching to existing server")

          {:ok,
           %{state | server_pid: nil, server_os_pid: nil, owns_server: false, status: :running}}

        true ->
          new_port = find_available_port()
          Logger.debug("Haxe server port #{state.port} is in use; relocating to #{new_port}")
          relocated = %{state | port: new_port}

          case start_haxe_server(relocated) do
            {:ok, pid2, os_pid2} ->
              Logger.debug("Haxe server relocated and started on port #{new_port}")

              started = %{
                relocated
                | server_pid: pid2,
                  server_os_pid: os_pid2,
                  owns_server: true,
                  status: :running
              }

              _ = write_cookie(started)
              {:ok, started}

            {:error, reason2} ->
              Logger.warning(
                "Failed to start Haxe server after relocation: #{inspect(reason2)}; will retry"
              )

              {:error,
               %{
                 relocated
                 | server_pid: nil,
                   server_os_pid: nil,
                   owns_server: false,
                   status: :error
               }}
          end
      end
    end
  end

  defp allow_external_attach?() do
    case System.get_env(@allow_external_attach_env) do
      value when is_binary(value) and value != "" ->
        String.trim(value) in ["1", "true", "TRUE", "yes", "YES"]

      _ ->
        false
    end
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

  defp cookie_path(project_root) do
    Path.join([project_root, @cookie_dir, @cookie_file])
  end

  defp cache_key(project_root, cmd, args) do
    material = %{
      project_root: project_root,
      haxe_cmd: cmd,
      haxe_args: args
    }

    :crypto.hash(:sha256, :erlang.term_to_binary(material))
    |> Base.encode16(case: :lower)
  end

  defp attach_to_cookie_server?(state) do
    case read_cookie(state.cookie_path) do
      {:ok, %{"version" => @cookie_version, "port" => cookie_port, "cache_key" => cookie_key}}
      when is_integer(cookie_port) and cookie_port == state.port and cookie_key == state.cache_key ->
        true

      _ ->
        false
    end
  rescue
    _ -> false
  end

  defp read_cookie(path) do
    with true <- File.exists?(path),
         {:ok, body} <- File.read(path),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, decoded}
    else
      false -> {:error, :missing}
      {:error, _} = err -> err
      _ -> {:error, :invalid}
    end
  end

  defp write_cookie(state) do
    data = %{
      "version" => @cookie_version,
      "port" => state.port,
      "cache_key" => state.cache_key,
      "owns_server" => state.owns_server,
      "server_os_pid" => state.server_os_pid,
      "written_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    dir = Path.dirname(state.cookie_path)
    _ = File.mkdir_p(dir)
    File.write(state.cookie_path, Jason.encode!(data) <> "\n")
  rescue
    _ -> :ok
  end

  defp maybe_remove_cookie(%{owns_server: true, cookie_path: path}) when is_binary(path) do
    _ = File.rm(path)
    :ok
  rescue
    _ -> :ok
  end

  defp maybe_remove_cookie(_state), do: :ok

  defp port_available?(port) do
    # Haxe (via lix/haxeshim) typically binds to the IPv6 wildcard (::) as a dual-stack
    # socket (v6only=false). Probe IPv6 dual-stack first, fall back to IPv4.
    #
    # NOTE: Avoid `reuseaddr` here. On some platforms it can mask an in-use port and lead
    # to false positives, which then crash the node-side server with EADDRINUSE.
    ipv6_opts = [:binary, active: false, ip: {0, 0, 0, 0, 0, 0, 0, 0}, ipv6_v6only: false]

    case :gen_tcp.listen(port, ipv6_opts) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _} ->
        case :gen_tcp.listen(port, [:binary, active: false]) do
          {:ok, socket} ->
            :gen_tcp.close(socket)
            true

          {:error, _} ->
            false
        end
    end
  end

  defp kill_process_tree(os_pid) when not is_integer(os_pid), do: :ok

  defp kill_process_tree(os_pid) when is_integer(os_pid) do
    kill_exe = System.find_executable("kill")
    pgrep_exe = System.find_executable("pgrep")

    if kill_exe != nil and pgrep_exe != nil do
      all = collect_descendant_pids(os_pid, pgrep_exe)
      # Kill children first to reduce re-parenting races.
      ordered = all |> Enum.uniq() |> Enum.reverse()

      _ = kill_pids(ordered, "-TERM", kill_exe)
      Process.sleep(100)

      remaining = Enum.filter(ordered, fn pid -> process_alive?(pid, kill_exe) end)
      _ = kill_pids(remaining, "-KILL", kill_exe)
    end

    :ok
  end

  defp collect_descendant_pids(root_pid, pgrep_exe) do
    do_collect_descendant_pids([root_pid], MapSet.new(), pgrep_exe)
    |> MapSet.to_list()
  end

  defp do_collect_descendant_pids([], acc, _pgrep_exe), do: acc

  defp do_collect_descendant_pids([pid | rest], acc, pgrep_exe) do
    if MapSet.member?(acc, pid) do
      do_collect_descendant_pids(rest, acc, pgrep_exe)
    else
      {out, status} =
        System.cmd(pgrep_exe, ["-P", Integer.to_string(pid)], stderr_to_stdout: true)

      children =
        if status == 0 do
          out
          |> String.split(~r/\s+/, trim: true)
          |> Enum.flat_map(fn s ->
            case Integer.parse(s) do
              {n, ""} -> [n]
              _ -> []
            end
          end)
        else
          []
        end

      do_collect_descendant_pids(rest ++ children, MapSet.put(acc, pid), pgrep_exe)
    end
  end

  defp process_alive?(pid, kill_exe) when is_integer(pid) do
    case System.cmd(kill_exe, ["-0", Integer.to_string(pid)], stderr_to_stdout: true) do
      {_out, 0} -> true
      {_out, _} -> false
    end
  end

  defp kill_pids([], _signal, _kill_exe), do: :ok

  defp kill_pids(pids, signal, kill_exe) do
    args = [signal | Enum.map(pids, &Integer.to_string/1)]
    _ = System.cmd(kill_exe, args, stderr_to_stdout: true)
    :ok
  end

  defp find_available_port(exclude_ports \\ MapSet.new()) do
    # Pick from a mid-range that avoids common dev ports (<10k) and OS ephemeral ports (often 49k+).
    # This reduces collisions with both local services and active outbound connections.
    base_port = 15_000 + rem(System.unique_integer([:positive]), 20_000)

    Enum.reduce_while(0..50, nil, fn offset, _acc ->
      port = base_port + offset

      if not MapSet.member?(exclude_ports, port) and port_available?(port) do
        {:halt, port}
      else
        {:cont, nil}
      end
    end) || pick_fallback_port(exclude_ports)
  end

  defp pick_fallback_port(exclude_ports) do
    # Better fallback with randomization.
    port = 35_000 + :rand.uniform(5_000)
    if MapSet.member?(exclude_ports, port), do: port + 1, else: port
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

  @doc false
  def ensure_haxeshim_server_port_env() do
    case System.get_env("HAXESHIM_SERVER_PORT") do
      nil ->
        port = find_available_port()
        System.put_env("HAXESHIM_SERVER_PORT", Integer.to_string(port))
        port

      value ->
        case Integer.parse(value) do
          {port, _} ->
            port

          :error ->
            port = find_available_port()
            System.put_env("HAXESHIM_SERVER_PORT", Integer.to_string(port))
            port
        end
    end
  end
end
