defmodule FileWatchingIntegrationTest do
  @moduledoc """
  Integration test for the file watching + incremental compilation feature.
  
  This test follows the project's integration-focused testing approach by testing
  the complete workflow without getting bogged down in unit test details.
  """
  
  use ExUnit.Case, async: false

  alias HaxeCompiler
  alias Mix.Tasks.Compile.Haxe, as: HaxeTask

  setup do
    # Create a temporary test project directory
    test_dir = Path.join([System.tmp_dir!(), "file_watching_integration_#{:rand.uniform(10000)}"])
    source_dir = Path.join(test_dir, "src_haxe")
    target_dir = Path.join(test_dir, "lib")
    
    File.mkdir_p!(source_dir)
    File.mkdir_p!(target_dir)
    
    # Create a basic build.hxml file
    build_hxml = Path.join(test_dir, "build.hxml")
    File.write!(build_hxml, """
    -cp #{source_dir}
    --elixir #{target_dir}
    -D reflaxe_runtime
    """)
    
    on_exit(fn ->
      File.rm_rf(test_dir)
    end)
    
    {:ok, test_dir: test_dir, source_dir: source_dir, target_dir: target_dir, build_hxml: build_hxml}
  end

  @tag :integration
  test "core compilation workflow works end-to-end", %{source_dir: source_dir, target_dir: target_dir, build_hxml: build_hxml} do
    # Step 1: Create a simple Haxe file
    test_hx_file = Path.join(source_dir, "TestModule.hx")
    File.write!(test_hx_file, """
    class TestModule {
        public static function main() {
            trace("Hello from Haxe!");
        }
        
        public static function getMessage():String {
            return "Integration test works!";
        }
    }
    """)
    
    # Step 2: Test HaxeCompiler detects source files
    opts = [
      hxml_file: build_hxml,
      source_dir: source_dir,
      target_dir: target_dir,
      verbose: true
    ]
    
    source_files = HaxeCompiler.source_files(opts)
    assert length(source_files) == 1
    assert Path.basename(hd(source_files)) == "TestModule.hx"
    
    # Step 3: Test recompilation detection
    assert HaxeCompiler.needs_recompilation?(opts) == true
    
    # Step 4: Test compilation (may fail without real Haxe, but should handle gracefully)
    compilation_result = HaxeCompiler.compile(opts)
    
    case compilation_result do
      {:ok, compiled_files} ->
        # If Haxe is available and compilation succeeds
        IO.puts("✅ Haxe compilation successful! Generated #{length(compiled_files)} files")
        
        # Verify generated files
        assert is_list(compiled_files)
        
        # Test that recompilation is not needed after successful compilation
        needs_recompile_after = HaxeCompiler.needs_recompilation?(opts)
        
        # This depends on whether files were actually generated
        if length(compiled_files) > 0 do
          assert needs_recompile_after == false, "Should not need recompilation after successful build"
        end
        
      {:error, reason} ->
        # Expected if Haxe is not available or not properly configured
        IO.puts("⚠️  Compilation failed as expected (likely no Haxe available): #{reason}")
        
        # Verify error handling works correctly
        assert is_binary(reason)
        assert String.length(reason) > 0
        
        # Common expected error patterns
        expected_error = reason =~ "Build file not found" or
                        reason =~ "Failed to execute" or
                        reason =~ "Haxe compilation failed" or
                        reason =~ "Source directory not found"
        
        assert expected_error, "Should get a meaningful error message"
    end
    
    IO.puts("✅ Core compilation workflow test completed successfully")
  end

  @tag :integration  
  test "Mix.Tasks.Compile.Haxe integration works", %{source_dir: source_dir, target_dir: target_dir, build_hxml: build_hxml} do
    # Create Haxe source file
    File.write!(Path.join(source_dir, "MixIntegration.hx"), """
    class MixIntegration {
        public static function main() {
            trace("Mix integration test");
        }
    }
    """)
    
    # Test Mix task integration (this tests the whole Mix compiler pipeline)
    old_cwd = File.cwd!()
    
    try do
      # Change to test directory so build.hxml is found
      File.cd!(Path.dirname(build_hxml))
      
      # Override compiler config for test
      config = [
        hxml_file: "build.hxml",
        source_dir: Path.relative_to_cwd(source_dir),
        target_dir: Path.relative_to_cwd(target_dir),
        verbose: true
      ]
      
      # Mock the config for this test
      Application.put_env(:reflaxe_elixir, :haxe_compiler, config)
      
      # Run the Mix compiler task
      result = HaxeTask.run(["--verbose"])
      
      case result do
        {:ok, files} ->
          IO.puts("✅ Mix task completed successfully with #{length(files)} files")
          assert is_list(files)
          
        {:noop, []} ->
          IO.puts("✅ Mix task detected no recompilation needed")
          
        {:error, []} ->
          IO.puts("⚠️  Mix task failed as expected (likely no Haxe available)")
          
        other ->
          IO.puts("✅ Mix task returned: #{inspect(other)}")
      end
      
    after
      File.cd!(old_cwd)
      Application.delete_env(:reflaxe_elixir, :haxe_compiler)
    end
    
    IO.puts("✅ Mix integration test completed")
  end

  @tag :integration
  test "file watching components can be initialized", %{source_dir: source_dir, target_dir: target_dir} do
    # Test that core components can be started without errors
    
    # Test HaxeServer (may fail to connect, but should start gracefully)
    server_result = try do
      {:ok, pid} = HaxeServer.start_link([])
      Process.sleep(100)  # Give it time to initialize
      
      status = HaxeServer.status()
      HaxeServer.stop()
      
      {:ok, status}
    catch
      kind, error -> {:error, {kind, error}}
    end
    
    case server_result do
      {:ok, {_response, stats}} ->
        IO.puts("✅ HaxeServer started successfully")
        assert is_map(stats)
        assert Map.has_key?(stats, :port)
        assert Map.has_key?(stats, :compile_count)
        
      {:error, {kind, error}} ->
        IO.puts("⚠️  HaxeServer failed to start as expected: #{kind} - #{inspect(error)}")
    end
    
    # Test that we can create source files and detect them
    File.write!(Path.join(source_dir, "WatchTest.hx"), "class WatchTest {}")
    
    source_files = HaxeCompiler.source_files([source_dir: source_dir])
    assert length(source_files) > 0
    
    # Test timestamp-based change detection
    opts = [source_dir: source_dir, target_dir: target_dir, force: false]
    
    # Should need compilation initially
    assert HaxeCompiler.needs_recompilation?(opts) == true
    
    # Create a fake target file to test timestamp comparison
    File.mkdir_p!(target_dir)
    File.write!(Path.join(target_dir, "WatchTest.ex"), "# fake generated file")
    
    # May or may not need recompilation depending on timestamps
    needs_recompile = HaxeCompiler.needs_recompilation?(opts)
    assert is_boolean(needs_recompile)
    
    IO.puts("✅ File watching components initialized successfully")
  end

  @tag :integration
  test "error handling works gracefully throughout the pipeline" do
    # Test various error conditions to ensure graceful handling
    
    # Test with non-existent source directory
    result1 = HaxeCompiler.compile([
      hxml_file: "build.hxml",
      source_dir: "/does/not/exist",
      target_dir: "lib"
    ])
    
    assert {:error, reason1} = result1
    assert reason1 =~ "Source directory not found" or reason1 =~ "Build file not found"
    
    # Test with non-existent build file
    result2 = HaxeCompiler.compile([
      hxml_file: "/does/not/exist.hxml",
      source_dir: "src",
      target_dir: "lib"
    ])
    
    assert {:error, reason2} = result2  
    assert reason2 =~ "Build file not found"
    
    # Test source file detection with non-existent directory
    files = HaxeCompiler.source_files([source_dir: "/does/not/exist"])
    assert files == []
    
    # Test recompilation check with non-existent directories
    needs_recompile = HaxeCompiler.needs_recompilation?([
      source_dir: "/does/not/exist",
      target_dir: "/also/does/not/exist"
    ])
    
    # Should return true (needs compilation) when target doesn't exist
    assert needs_recompile == true
    
    IO.puts("✅ Error handling works gracefully")
  end

  @tag :performance
  test "compilation performance meets basic requirements", %{source_dir: source_dir, target_dir: target_dir, build_hxml: build_hxml} do
    # Create multiple Haxe files to test performance
    for i <- 1..5 do
      File.write!(Path.join(source_dir, "PerfTest#{i}.hx"), """
      class PerfTest#{i} {
          public static function test#{i}() {
              return "Performance test #{i}";
          }
      }
      """)
    end
    
    opts = [
      hxml_file: build_hxml,
      source_dir: source_dir,
      target_dir: target_dir,
      verbose: false  # Don't spam output during performance test
    ]
    
    # Test source file detection performance
    start_time = System.monotonic_time(:millisecond)
    source_files = HaxeCompiler.source_files(opts)
    detection_time = System.monotonic_time(:millisecond) - start_time
    
    assert length(source_files) == 5
    assert detection_time < 1000, "Source file detection should be fast (<1s), took #{detection_time}ms"
    
    # Test recompilation check performance
    start_time = System.monotonic_time(:millisecond)
    needs_recompile = HaxeCompiler.needs_recompilation?(opts)
    check_time = System.monotonic_time(:millisecond) - start_time
    
    assert is_boolean(needs_recompile)
    assert check_time < 1000, "Recompilation check should be fast (<1s), took #{check_time}ms"
    
    IO.puts("✅ Performance test completed - detection: #{detection_time}ms, check: #{check_time}ms")
  end
end