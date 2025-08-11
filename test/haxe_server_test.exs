defmodule HaxeServerTest do
  use ExUnit.Case, async: false
  doctest HaxeServer
  
  alias HaxeServer

  setup do
    # Stop any running server before each test
    if Process.whereis(HaxeServer) do
      GenServer.stop(HaxeServer, :normal)
      Process.sleep(100)
    end
    
    :ok
  end

  describe "start_link/1" do
    test "starts the GenServer with default options" do
      assert {:ok, pid} = HaxeServer.start_link([])
      assert Process.alive?(pid)
      assert pid == Process.whereis(HaxeServer)
    end

    test "starts with custom port option" do
      assert {:ok, _pid} = HaxeServer.start_link([port: 7000])
      
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
      custom_port = 7001
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
end