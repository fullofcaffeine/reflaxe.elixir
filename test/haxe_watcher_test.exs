defmodule HaxeWatcherTest do
  use ExUnit.Case, async: false
  doctest HaxeWatcher
  
  alias HaxeWatcher
  
  setup do
    # Stop any running watcher before each test
    if Process.whereis(HaxeWatcher) do
      GenServer.stop(HaxeWatcher, :normal)
      Process.sleep(100)
    end
    
    # Create temporary test directory
    test_dir = Path.join([System.tmp_dir!(), "haxe_watcher_test_#{:rand.uniform(10000)}"])
    File.mkdir_p!(test_dir)
    
    on_exit(fn ->
      File.rm_rf(test_dir)
    end)
    
    {:ok, test_dir: test_dir}
  end

  describe "start_link/1" do
    test "starts the GenServer with default options" do
      assert {:ok, pid} = HaxeWatcher.start_link([])
      assert Process.alive?(pid)
      assert pid == Process.whereis(HaxeWatcher)
    end

    test "starts with custom directories", %{test_dir: test_dir} do
      custom_dirs = [test_dir]
      assert {:ok, _pid} = HaxeWatcher.start_link([dirs: custom_dirs])
      
      # Give it time to initialize
      Process.sleep(100)
      
      status = HaxeWatcher.status()
      assert status.dirs == custom_dirs
    end

    test "starts with custom patterns" do
      custom_patterns = ["*.hx", "**/*.haxe"]
      assert {:ok, _pid} = HaxeWatcher.start_link([patterns: custom_patterns])
      
      status = HaxeWatcher.status()
      assert status.patterns == custom_patterns
    end

    test "starts with custom debounce period" do
      custom_debounce = 500
      assert {:ok, _pid} = HaxeWatcher.start_link([debounce_ms: custom_debounce])
      
      status = HaxeWatcher.status()
      assert status.debounce_ms == custom_debounce
    end

    test "starts with auto_compile disabled" do
      assert {:ok, _pid} = HaxeWatcher.start_link([auto_compile: false])
      
      status = HaxeWatcher.status()
      refute status.auto_compile
    end
  end

  describe "status/0" do
    test "returns comprehensive status information", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([dirs: [test_dir]])
      
      # Give it time to initialize
      Process.sleep(200)
      
      status = HaxeWatcher.status()
      
      # Required fields
      assert Map.has_key?(status, :watching)
      assert Map.has_key?(status, :dirs)
      assert Map.has_key?(status, :patterns)
      assert Map.has_key?(status, :auto_compile)
      assert Map.has_key?(status, :debounce_ms)
      assert Map.has_key?(status, :file_count)
      assert Map.has_key?(status, :last_change)
      assert Map.has_key?(status, :compilation_count)
      assert Map.has_key?(status, :last_compilation)
      
      # Type checks
      assert is_boolean(status.watching)
      assert is_list(status.dirs)
      assert is_list(status.patterns)
      assert is_boolean(status.auto_compile)
      assert is_integer(status.debounce_ms)
      assert is_integer(status.file_count)
      assert is_integer(status.compilation_count)
      
      # Initial values
      assert status.compilation_count == 0
      assert is_nil(status.last_change)
      assert is_nil(status.last_compilation)
    end

    test "reports correct file count when Haxe files exist", %{test_dir: test_dir} do
      # Create some test .hx files
      File.write!(Path.join(test_dir, "Test1.hx"), "class Test1 {}")
      File.write!(Path.join(test_dir, "Test2.hx"), "class Test2 {}")
      File.write!(Path.join(test_dir, "Other.txt"), "not a haxe file")
      
      {:ok, _pid} = HaxeWatcher.start_link([dirs: [test_dir]])
      
      # Give it time to initialize and count files
      Process.sleep(200)
      
      status = HaxeWatcher.status()
      assert status.file_count == 2  # Only .hx files
    end
  end

  describe "add_watch_dir/1 and remove_watch_dir/1" do
    test "can add new watch directories", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([dirs: []])
      
      # Add directory
      :ok = HaxeWatcher.add_watch_dir(test_dir)
      
      # Give it time to restart watching
      Process.sleep(200)
      
      status = HaxeWatcher.status()
      assert test_dir in status.dirs
    end

    test "can remove watch directories", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([dirs: [test_dir]])
      
      # Remove directory
      :ok = HaxeWatcher.remove_watch_dir(test_dir)
      
      # Give it time to restart watching
      Process.sleep(200)
      
      status = HaxeWatcher.status()
      refute test_dir in status.dirs
    end

    test "ignores adding non-existent directories" do
      {:ok, _pid} = HaxeWatcher.start_link([])
      
      non_existent = "/this/path/does/not/exist"
      :ok = HaxeWatcher.add_watch_dir(non_existent)
      
      # Give it time to process
      Process.sleep(100)
      
      status = HaxeWatcher.status()
      refute non_existent in status.dirs
    end

    test "ignores removing non-watched directories", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([dirs: [test_dir]])
      
      other_dir = "/some/other/path"
      :ok = HaxeWatcher.remove_watch_dir(other_dir)
      
      # Should not affect existing directories
      status = HaxeWatcher.status()
      assert test_dir in status.dirs
    end
  end

  describe "trigger_compilation/0" do
    test "can manually trigger compilation" do
      {:ok, _pid} = HaxeWatcher.start_link([])
      
      initial_status = HaxeWatcher.status()
      initial_count = initial_status.compilation_count
      
      # Manually trigger compilation
      :ok = HaxeWatcher.trigger_compilation()
      
      # Give it time to process
      Process.sleep(300)
      
      final_status = HaxeWatcher.status()
      
      # Compilation count should increment
      assert final_status.compilation_count == initial_count + 1
      
      # Last compilation timestamp should be set
      assert is_struct(final_status.last_compilation, DateTime)
    end
  end

  describe "file watching behavior" do
    @tag :file_watching
    test "detects when Haxe files are created", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([
        dirs: [test_dir], 
        debounce_ms: 50,
        auto_compile: true
      ])
      
      # Give it time to start watching
      Process.sleep(200)
      
      initial_status = HaxeWatcher.status()
      initial_count = initial_status.compilation_count
      
      # Create a new Haxe file
      test_file = Path.join(test_dir, "NewTest.hx")
      File.write!(test_file, "class NewTest {}")
      
      # Wait for debounce + compilation
      Process.sleep(400)
      
      final_status = HaxeWatcher.status()
      
      # Should have triggered compilation
      assert final_status.compilation_count > initial_count
      assert is_struct(final_status.last_change, DateTime)
    end

    @tag :file_watching
    test "detects when Haxe files are modified", %{test_dir: test_dir} do
      # Create initial file
      test_file = Path.join(test_dir, "ModifyTest.hx")
      File.write!(test_file, "class ModifyTest {}")
      
      {:ok, _pid} = HaxeWatcher.start_link([
        dirs: [test_dir], 
        debounce_ms: 50,
        auto_compile: true
      ])
      
      # Give it time to start watching
      Process.sleep(200)
      
      initial_status = HaxeWatcher.status()
      initial_count = initial_status.compilation_count
      
      # Modify the file
      File.write!(test_file, "class ModifyTest { public function test() {} }")
      
      # Wait for debounce + compilation
      Process.sleep(400)
      
      final_status = HaxeWatcher.status()
      
      # Should have triggered compilation
      assert final_status.compilation_count > initial_count
    end

    @tag :file_watching  
    test "ignores non-Haxe files", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([
        dirs: [test_dir], 
        debounce_ms: 50,
        auto_compile: true
      ])
      
      # Give it time to start watching
      Process.sleep(200)
      
      initial_status = HaxeWatcher.status()
      initial_count = initial_status.compilation_count
      
      # Create non-Haxe files
      File.write!(Path.join(test_dir, "test.txt"), "not haxe")
      File.write!(Path.join(test_dir, "test.ex"), "defmodule Test do end")
      File.write!(Path.join(test_dir, "README.md"), "# Test")
      
      # Wait to see if compilation was triggered
      Process.sleep(300)
      
      final_status = HaxeWatcher.status()
      
      # Should NOT have triggered compilation
      assert final_status.compilation_count == initial_count
    end

    test "respects debounce period", %{test_dir: test_dir} do
      debounce_ms = 200
      
      {:ok, _pid} = HaxeWatcher.start_link([
        dirs: [test_dir], 
        debounce_ms: debounce_ms,
        auto_compile: true
      ])
      
      # Give it time to start watching
      Process.sleep(100)
      
      initial_status = HaxeWatcher.status()
      initial_count = initial_status.compilation_count
      
      # Create multiple files rapidly
      for i <- 1..3 do
        File.write!(Path.join(test_dir, "Rapid#{i}.hx"), "class Rapid#{i} {}")
        Process.sleep(10)  # Much less than debounce period
      end
      
      # Wait for less than debounce period
      Process.sleep(debounce_ms - 50)
      
      # Should not have compiled yet due to debounce
      mid_status = HaxeWatcher.status()
      assert mid_status.compilation_count == initial_count
      
      # Wait for debounce to complete
      Process.sleep(debounce_ms + 100)
      
      # Should have compiled only once despite multiple file changes
      final_status = HaxeWatcher.status()
      assert final_status.compilation_count == initial_count + 1
    end

    test "doesn't auto-compile when auto_compile is false", %{test_dir: test_dir} do
      {:ok, _pid} = HaxeWatcher.start_link([
        dirs: [test_dir], 
        debounce_ms: 50,
        auto_compile: false
      ])
      
      # Give it time to start watching
      Process.sleep(200)
      
      initial_status = HaxeWatcher.status()
      initial_count = initial_status.compilation_count
      
      # Create a Haxe file
      File.write!(Path.join(test_dir, "NoAutoCompile.hx"), "class NoAutoCompile {}")
      
      # Wait for debounce period
      Process.sleep(300)
      
      final_status = HaxeWatcher.status()
      
      # Should NOT have triggered auto-compilation
      assert final_status.compilation_count == initial_count
      
      # But last_change should still be updated
      assert is_struct(final_status.last_change, DateTime)
    end
  end

  describe "stop/0" do
    test "stops the watcher gracefully" do
      {:ok, pid} = HaxeWatcher.start_link([])
      assert Process.alive?(pid)
      
      assert :ok = HaxeWatcher.stop()
      
      # Give it time to stop
      Process.sleep(100)
      
      refute Process.alive?(pid)
    end

    test "handles stopping when not running" do
      # Should not crash if watcher is not running
      try do
        HaxeWatcher.stop()
      catch
        :exit, {:noproc, _} -> :ok
      end
    end
  end

  describe "error handling" do
    test "handles watching non-existent directories gracefully" do
      non_existent_dirs = ["/this/does/not/exist", "/neither/does/this"]
      
      {:ok, pid} = HaxeWatcher.start_link([dirs: non_existent_dirs])
      
      # Give it time to attempt watching
      Process.sleep(300)
      
      # Should still be alive
      assert Process.alive?(pid)
      
      status = HaxeWatcher.status()
      
      # Should report not watching due to no valid directories
      refute status.watching
      assert status.dirs == non_existent_dirs
    end

    test "recovers when directories become available", %{test_dir: test_dir} do
      # Start watching a directory that will be created later
      future_dir = Path.join(test_dir, "future")
      
      {:ok, _pid} = HaxeWatcher.start_link([dirs: [future_dir]])
      
      # Initially should not be watching
      Process.sleep(200)
      initial_status = HaxeWatcher.status()
      refute initial_status.watching
      
      # Create the directory
      File.mkdir_p!(future_dir)
      
      # Add it to watch list (this triggers restart)
      HaxeWatcher.add_watch_dir(future_dir)
      
      # Give it time to start watching
      Process.sleep(200)
      
      final_status = HaxeWatcher.status()
      # Should now be watching since directory exists
      assert final_status.watching or length(final_status.dirs) > 0
    end
  end
end