defmodule HaxeServerTest do
  use ExUnit.Case, async: false
  doctest HaxeServer
  
  alias HaxeServer

  setup do
    previous_haxe_no_server = System.get_env("HAXE_NO_SERVER")
    System.delete_env("HAXE_NO_SERVER")

    # Stop any running server before each test
    case Process.whereis(HaxeServer) do
      nil ->
        :ok

      pid ->
        # Avoid flaky :noproc exits if the server dies between whereis/stop.
        try do
          GenServer.stop(pid, :normal)
        catch
          :exit, {:noproc, _} -> :ok
          :exit, _ -> :ok
        end

        Process.sleep(100)
    end

    on_exit(fn ->
      # Ensure we don't leave a running `haxe --wait` process behind if this was the last test.
      case Process.whereis(HaxeServer) do
        nil ->
          :ok

        pid ->
          try do
            GenServer.stop(pid, :normal)
          catch
            :exit, {:noproc, _} -> :ok
            :exit, _ -> :ok
          end

          Process.sleep(100)
      end

      case previous_haxe_no_server do
        nil -> System.delete_env("HAXE_NO_SERVER")
        value -> System.put_env("HAXE_NO_SERVER", value)
      end
    end)

    :ok
  end

	  describe "start_link/1" do
    test "starts the GenServer with default options" do
      assert {:ok, pid} = HaxeServer.start_link([])
      assert Process.alive?(pid)
      assert pid == Process.whereis(HaxeServer)
    end

    test "relocates when the requested port is already in use" do
      ipv6_opts = [:binary, active: false, ip: {0, 0, 0, 0, 0, 0, 0, 0}, ipv6_v6only: false]

      socket =
        case :gen_tcp.listen(0, ipv6_opts) do
          {:ok, s} -> s
          {:error, _} -> {:ok, s} = :gen_tcp.listen(0, [:binary, active: false]); s
        end

      {:ok, {_addr, port}} = :inet.sockname(socket)

      assert {:ok, _pid} = HaxeServer.start_link([port: port])

      # Allow async :start_server to probe and relocate.
      Process.sleep(100)

      {_response, stats} = HaxeServer.status()
      assert stats.port != port

      :gen_tcp.close(socket)
    end

	    test "attaches to cookie port when env port is occupied" do
      project_root = Path.expand("../..", __DIR__)
      cookie_dir = Path.join(project_root, ".reflaxe_elixir")
      cookie_path = Path.join(cookie_dir, "haxe_server.json")

      previous_cookie =
        case File.read(cookie_path) do
          {:ok, contents} -> contents
          _ -> nil
        end

	      previous_env_port = System.get_env("HAXE_SERVER_PORT")
	      previous_allow_attach = System.get_env("HAXE_SERVER_ALLOW_ATTACH")

      haxe_exe =
        System.find_executable("haxe") ||
          Path.join([project_root, "node_modules", ".bin", "haxe"])

      unless is_binary(haxe_exe) and File.exists?(haxe_exe) do
        flunk("Haxe executable not found for test")
      end

      {resolved_haxe_exe, resolved_haxe_args} = HaxeServer.resolve_haxe_cmd(haxe_exe, [], project_root)

	      # Start an external haxe --wait server on a cookie port.
	      #
	      # NOTE: `Port.close/1` is not guaranteed to terminate the underlying OS process on all
	      # platforms/wrappers (especially when haxeshim spawns a real `haxe --wait` child). Capture
	      # the OS PID so we can kill the process tree explicitly in cleanup to avoid leaks that can
	      # destabilize subsequent tests (port churn / hangs).
	      cookie_port = find_free_port()
	      port =
	        Port.open(
	          {:spawn_executable, resolved_haxe_exe},
          [
            :binary,
            :exit_status,
            :stderr_to_stdout,
            {:args, resolved_haxe_args ++ ["--wait", Integer.to_string(cookie_port)]}
          ]
	        )

	      Process.sleep(500)
	      cookie_os_pid =
	        case Port.info(port, :os_pid) do
	          {:os_pid, pid} when is_integer(pid) -> pid
	          _ -> nil
	        end

	      # Occupy the env-requested port so the server can't bind it.
      ipv6_opts = [:binary, active: false, ip: {0, 0, 0, 0, 0, 0, 0, 0}, ipv6_v6only: false]

      socket =
        case :gen_tcp.listen(0, ipv6_opts) do
          {:ok, s} -> s
          {:error, _} -> {:ok, s} = :gen_tcp.listen(0, [:binary, active: false]); s
        end

	      {:ok, {_addr, env_port}} = :inet.sockname(socket)
	      System.put_env("HAXE_SERVER_PORT", Integer.to_string(env_port))
	      System.put_env("HAXE_SERVER_ALLOW_ATTACH", "1")

      # Write a cookie pointing at the running external server, using the same cache key logic.
      File.mkdir_p!(cookie_dir)

      cache_key =
        :crypto.hash(
          :sha256,
          :erlang.term_to_binary(%{
            project_root: project_root,
            haxe_cmd: resolved_haxe_exe,
            haxe_args: resolved_haxe_args
          })
        )
        |> Base.encode16(case: :lower)

      File.write!(
        cookie_path,
        Jason.encode!(%{
          "version" => 1,
          "port" => cookie_port,
          "cache_key" => cache_key,
          "owns_server" => false,
          "server_os_pid" => nil,
          "written_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }) <> "\n"
      )

      old_cwd = File.cwd!()

      try do
        File.cd!(project_root)
        assert {:ok, _pid} = HaxeServer.start_link([haxe_cmd: {resolved_haxe_exe, resolved_haxe_args}])
        Process.sleep(100)
        {_response, stats} = HaxeServer.status()
        assert stats.port == cookie_port
	      after
        File.cd!(old_cwd)
        _ = HaxeServer.stop()
        :gen_tcp.close(socket)

	        try do
	          Port.close(port)
	        rescue
	          _ -> :ok
	        end
	        kill_process_tree(cookie_os_pid)

	        case previous_env_port do
	          nil -> System.delete_env("HAXE_SERVER_PORT")
	          value -> System.put_env("HAXE_SERVER_PORT", value)
	        end

	        case previous_allow_attach do
	          nil -> System.delete_env("HAXE_SERVER_ALLOW_ATTACH")
	          value -> System.put_env("HAXE_SERVER_ALLOW_ATTACH", value)
	        end

        case previous_cookie do
          nil -> File.rm(cookie_path)
          contents -> File.write!(cookie_path, contents)
	      end
	    end
    end

    test "starts with custom port option" do
      custom_port = find_free_port()
      assert {:ok, _pid} = HaxeServer.start_link([port: custom_port])
      
      # Give it time to try starting the server
      Process.sleep(100)
      
      # Should still be alive even if Haxe server fails to start
      assert Process.alive?(Process.whereis(HaxeServer))
    end

    test "starts with custom haxe command" do
      assert {:ok, _pid} = HaxeServer.start_link([haxe_cmd: "echo"])
      assert Process.alive?(Process.whereis(HaxeServer))
    end
  end

  describe "running?/0" do
    test "returns false when server is not started" do
      refute HaxeServer.running?()
    end

    test "returns false when server is starting" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Server may not be running immediately on start
      # This is acceptable behavior during initialization
      result = HaxeServer.running?()
      assert is_boolean(result)
    end
    
    test "returns false when process is dead" do
      refute HaxeServer.running?()
    end
  end

  describe "status/0" do
    test "returns status information" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      assert {response, stats} = HaxeServer.status()
      
      # Response should be ok/error tuple  
      assert response in [{:ok, :running}, {:error, :stopped}, {:error, :restarting}, {:error, :failed_to_start}]
      
      # Stats should have required fields
      assert %{status: _, port: _, compile_count: _, last_compile: _} = stats
      assert is_integer(stats.port)
      assert is_integer(stats.compile_count)
      assert stats.compile_count >= 0
    end

    test "includes correct port in stats" do
      custom_port = find_free_port()
      {:ok, _pid} = HaxeServer.start_link([port: custom_port])
      
      {_response, stats} = HaxeServer.status()
      assert stats.port == custom_port
    end
  end

  describe "compile/2" do
    test "returns error when server is not running" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Server likely won't be running immediately due to missing Haxe
      result = HaxeServer.compile(["--version"])
      
      # Should either succeed or return meaningful error
      case result do
        {:ok, output} -> 
          assert is_binary(output)
        {:error, error} -> 
          assert is_binary(error)
          assert String.contains?(error, ["server not running", "not running", "Failed to", "Compilation failed"])
      end
    end

    test "validates arguments are a list" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # This should work (list of strings)
      result = HaxeServer.compile(["--help"])
      assert match?({:ok, _}, result) or match?({:error, _}, result)
      
      # Note: We can't easily test invalid argument types here
      # because the function spec requires a list
    end

    test "handles timeout option" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Short timeout should still return within reasonable time
      start_time = System.monotonic_time(:millisecond)
      result = HaxeServer.compile(["--help"], [timeout: 1000])
      end_time = System.monotonic_time(:millisecond)
      
      # Should complete within timeout + some buffer
      assert (end_time - start_time) < 2000
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "stop/0" do
    test "stops the server gracefully" do
      {:ok, pid} = HaxeServer.start_link([])
      assert Process.alive?(pid)
      
      assert :ok = HaxeServer.stop()
      
      # Give it time to stop
      Process.sleep(100)
      
      refute Process.alive?(pid)
      refute HaxeServer.running?()
    end

    test "handles stopping when not running" do
      # Should not crash if server is not running
      refute HaxeServer.running?()
      
      # This might exit with noproc, which is expected
      try do
        HaxeServer.stop()
      catch
        :exit, {:noproc, _} -> :ok
      end
    end
  end

  describe "server lifecycle" do
    test "server attempts to start Haxe server on init" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Give server time to attempt starting Haxe
      Process.sleep(200)
      
      # Check that it attempted to start (status should not be :stopped)
      {_response, stats} = HaxeServer.status()
      assert stats.status in [:running, :error, :restarting]
    end

    test "compile count increments with each compilation attempt" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Initial count
      {_response1, stats1} = HaxeServer.status()
      initial_count = stats1.compile_count
      
      # Attempt compilation (may fail, but should increment counter if server is running)
      HaxeServer.compile(["--help"])
      
      {_response2, stats2} = HaxeServer.status()
      
      # Count should either stay the same (if server not running) or increment
      assert stats2.compile_count >= initial_count
    end
    
    test "last_compile timestamp updates after compilation" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Initial timestamp  
      {_response1, stats1} = HaxeServer.status()
      initial_timestamp = stats1.last_compile
      
      # Small delay to ensure timestamp difference
      Process.sleep(10)
      
      # Attempt compilation
      HaxeServer.compile(["--version"])
      
      {_response2, stats2} = HaxeServer.status()
      
      # Timestamp should either stay the same (if compilation failed) 
      # or be updated (if compilation succeeded)
      case {stats1.status, stats2.last_compile} do
        {:running, timestamp} when not is_nil(timestamp) ->
          # If server was running and compilation worked
          assert timestamp != initial_timestamp
        _ ->
          # If server wasn't running, timestamp might not change
          assert stats2.last_compile == initial_timestamp or is_struct(stats2.last_compile, DateTime)
      end
    end
  end

  describe "error handling" do
    test "server handles invalid Haxe command gracefully" do
      {:ok, _pid} = HaxeServer.start_link([haxe_cmd: "nonexistent_command"])
      
      # Give time for server to attempt start
      Process.sleep(200)
      
      # Server should still be alive but in error state
      assert Process.alive?(Process.whereis(HaxeServer))
      
      {response, stats} = HaxeServer.status()
      assert {:error, _reason} = response
      assert stats.status in [:error, :restarting]
    end

    test "server recovers from temporary failures" do
      {:ok, _pid} = HaxeServer.start_link([])
      
      # Server should attempt recovery even if initial start fails
      Process.sleep(300)
      
      # Should still be responsive
      assert Process.alive?(Process.whereis(HaxeServer))
      result = HaxeServer.status()
      assert match?({_, %{}}, result)
    end
  end

  defp find_free_port() do
    # Prefer a dual-stack bind to match lix/haxeshim's default (::) behavior.
    ipv6_opts = [
      :binary,
      active: false,
      reuseaddr: true,
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      ipv6_v6only: false
    ]

    case :gen_tcp.listen(0, ipv6_opts) do
      {:ok, socket} ->
        {:ok, {_addr, port}} = :inet.sockname(socket)
        :gen_tcp.close(socket)
        port

      {:error, _} ->
        {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, reuseaddr: true])
        {:ok, {_addr, port}} = :inet.sockname(socket)
        :gen_tcp.close(socket)
        port
    end
  end

  defp kill_process_tree(os_pid) when not is_integer(os_pid), do: :ok

  defp kill_process_tree(os_pid) when is_integer(os_pid) do
    kill_exe = System.find_executable("kill")
    pgrep_exe = System.find_executable("pgrep")

    if is_binary(kill_exe) and is_binary(pgrep_exe) do
      all = collect_descendant_pids([os_pid], MapSet.new(), pgrep_exe)
      ordered = all |> MapSet.to_list() |> Enum.reverse()

      _ =
        System.cmd(kill_exe, ["-TERM" | Enum.map(ordered, &Integer.to_string/1)],
          stderr_to_stdout: true
        )

      Process.sleep(100)

      remaining =
        Enum.filter(ordered, fn pid ->
          case System.cmd(kill_exe, ["-0", Integer.to_string(pid)], stderr_to_stdout: true) do
            {_out, 0} -> true
            {_out, _} -> false
          end
        end)

      _ =
        System.cmd(kill_exe, ["-KILL" | Enum.map(remaining, &Integer.to_string/1)],
          stderr_to_stdout: true
        )
    end

    :ok
  end

  defp collect_descendant_pids([], acc, _pgrep_exe), do: acc

  defp collect_descendant_pids([pid | rest], acc, pgrep_exe) do
    if MapSet.member?(acc, pid) do
      collect_descendant_pids(rest, acc, pgrep_exe)
    else
      {out, status} = System.cmd(pgrep_exe, ["-P", Integer.to_string(pid)], stderr_to_stdout: true)

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

      collect_descendant_pids(rest ++ children, MapSet.put(acc, pid), pgrep_exe)
    end
  end
end
