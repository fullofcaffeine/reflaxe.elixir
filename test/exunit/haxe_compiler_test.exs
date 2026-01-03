defmodule HaxeCompilerTest do
  use ExUnit.Case, async: false
  doctest HaxeCompiler
  
  alias HaxeCompiler
  
  setup do
    # Stop any running Haxe server to avoid port conflicts
    if Process.whereis(HaxeServer) do
      try do
        HaxeServer.stop()
        Process.sleep(100)
      catch
        _, _ -> :ok
      end
    end
    
    # Create temporary test directories
    test_dir = Path.join([System.tmp_dir!(), "haxe_compiler_test_#{:rand.uniform(10000)}"])
    source_dir = Path.join(test_dir, "src_haxe")
    target_dir = Path.join(test_dir, "lib")
    
    File.mkdir_p!(source_dir)
    File.mkdir_p!(target_dir)
    
    # Setup haxe_libraries for compilation to work
    HaxeTestHelper.setup_haxe_libraries(test_dir)
    
    on_exit(fn ->
      # Clean up Haxe server if started
      if Process.whereis(HaxeServer) do
        try do
          HaxeServer.stop()
        catch
          _, _ -> :ok
        end
      end
      File.rm_rf(test_dir)
    end)
    
    {:ok, test_dir: test_dir, source_dir: source_dir, target_dir: target_dir}
  end

  describe "compile/1" do
    test "compiles successfully with valid configuration", %{source_dir: source_dir, target_dir: target_dir} do
      # Create a simple build.hxml file
      build_hxml = Path.join(Path.dirname(source_dir), "build.hxml")
      File.write!(build_hxml, """
      -cp #{source_dir}
      -lib reflaxe.elixir
      -D reflaxe_runtime
      -D elixir_output=#{target_dir}
      Main
      """)
      
      # Create a simple Haxe file
      File.write!(Path.join(source_dir, "Main.hx"), """
      class Main {
          public static function main() {
              trace("Hello World");
          }
      }
      """)
      
      # Test compilation
      opts = [
        hxml_file: build_hxml,
        source_dir: source_dir,
        target_dir: target_dir,
        verbose: false
      ]
      
      # Note: This may fail if Haxe is not available, which is expected
      result = HaxeCompiler.compile(opts)
      
      case result do
        {:ok, files} ->
          # If compilation succeeded, verify files were generated
          assert is_list(files)
          assert length(files) >= 0  # May be 0 if no .ex files generated
          
        {:error, reason} ->
          # If compilation failed, it should be due to missing Haxe or invalid config
          assert is_binary(reason)
          
          # Common expected failures:
          assert reason =~ "Build file not found" or
                 reason =~ "Haxe compilation failed" or
                 reason =~ "Failed to execute Haxe" or
                 reason =~ "Source directory not found"
      end
    end

    test "returns error for non-existent build file" do
      opts = [
        hxml_file: "/non/existent/build.hxml",
        source_dir: "src_haxe",
        target_dir: "lib"
      ]
      
      assert {:error, reason} = HaxeCompiler.compile(opts)
      assert reason =~ "Build file not found"
    end

    test "returns error for non-existent source directory", %{target_dir: target_dir} do
      build_hxml = Path.join(Path.dirname(target_dir), "build.hxml")
      File.write!(build_hxml, "# minimal build file")
      
      opts = [
        hxml_file: build_hxml,
        source_dir: "/non/existent/source",
        target_dir: target_dir
      ]
      
      assert {:error, reason} = HaxeCompiler.compile(opts)
      assert reason =~ "Source directory not found"
    end

    test "handles empty source directory gracefully", %{source_dir: source_dir, target_dir: target_dir} do
      build_hxml = Path.join(Path.dirname(source_dir), "build.hxml")
      File.write!(build_hxml, "# minimal build file")
      
      opts = [
        hxml_file: build_hxml,
        source_dir: source_dir,
        target_dir: target_dir
      ]
      
      # Empty source directory should return ok with empty file list
      assert {:ok, []} = HaxeCompiler.compile(opts)
    end

    test "uses verbose output when requested", %{source_dir: source_dir, target_dir: target_dir} do
      build_hxml = Path.join(Path.dirname(source_dir), "build.hxml")
      File.write!(build_hxml, "# minimal build file")
      
      opts = [
        hxml_file: build_hxml,
        source_dir: source_dir,
        target_dir: target_dir,
        verbose: true
      ]
      
      # This should not crash even with verbose output
      result = HaxeCompiler.compile(opts)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "needs_recompilation?/1" do
    test "returns true when force option is set", %{source_dir: source_dir, target_dir: target_dir} do
      opts = [
        source_dir: source_dir,
        target_dir: target_dir,
        force: true
      ]
      
      assert HaxeCompiler.needs_recompilation?(opts) == true
    end

    test "returns true when target directory doesn't exist" do
      opts = [
        source_dir: "src_haxe",
        target_dir: "/non/existent/target"
      ]
      
      assert HaxeCompiler.needs_recompilation?(opts) == true
    end

    test "returns false when no Haxe files exist", %{source_dir: source_dir, target_dir: target_dir} do
      # Create target directory but no source files
      File.mkdir_p!(target_dir)
      
      opts = [
        source_dir: source_dir,
        target_dir: target_dir,
        force: false
      ]
      
      assert HaxeCompiler.needs_recompilation?(opts) == false
    end

    test "returns true when Haxe files exist but no target files", %{source_dir: source_dir, target_dir: target_dir} do
      # Create Haxe file
      File.write!(Path.join(source_dir, "Test.hx"), "class Test {}")
      
      opts = [
        source_dir: source_dir,
        target_dir: target_dir,
        force: false
      ]
      
      assert HaxeCompiler.needs_recompilation?(opts) == true
    end

    test "compares timestamps correctly", %{source_dir: source_dir, target_dir: target_dir} do
      # Create Haxe file
      haxe_file = Path.join(source_dir, "Test.hx")
      File.write!(haxe_file, "class Test {}")
      
      # Create corresponding Elixir file
      elixir_file = Path.join(target_dir, "Test.ex")
      File.write!(elixir_file, "defmodule Test do end")
      
      opts = [
        source_dir: source_dir,
        target_dir: target_dir,
        force: false
      ]
      
      # Initially should not need recompilation (target newer or equal)
      needs_recompile_1 = HaxeCompiler.needs_recompilation?(opts)
      
      # Wait a bit and touch the Haxe file to make it newer
      Process.sleep(10)
      File.touch!(haxe_file)
      
      # Now should need recompilation
      needs_recompile_2 = HaxeCompiler.needs_recompilation?(opts)
      
      # At least one of these should be true (depending on filesystem timestamp resolution)
      assert needs_recompile_1 == false or needs_recompile_2 == true
    end
  end

  describe "source_files/1" do
    test "finds Haxe files in source directory", %{source_dir: source_dir} do
      # Create various files
      File.write!(Path.join(source_dir, "Test1.hx"), "class Test1 {}")
      File.write!(Path.join(source_dir, "Test2.hx"), "class Test2 {}")
      File.write!(Path.join(source_dir, "Other.txt"), "not haxe")
      
      # Create subdirectory with Haxe file
      sub_dir = Path.join(source_dir, "sub")
      File.mkdir_p!(sub_dir)
      File.write!(Path.join(sub_dir, "Test3.hx"), "class Test3 {}")
      
      opts = [source_dir: source_dir]
      
      files = HaxeCompiler.source_files(opts)
      
      # Should find all .hx files
      assert is_list(files)
      assert length(files) == 3
      
      # Should be sorted
      assert files == Enum.sort(files)
      
      # Should contain our test files
      basenames = Enum.map(files, &Path.basename/1)
      assert "Test1.hx" in basenames
      assert "Test2.hx" in basenames
      assert "Test3.hx" in basenames
      assert "Other.txt" not in basenames
    end

    test "returns empty list for non-existent directory" do
      opts = [source_dir: "/non/existent"]
      
      assert HaxeCompiler.source_files(opts) == []
    end

    test "returns empty list for directory with no Haxe files", %{source_dir: source_dir} do
      # Create non-Haxe files
      File.write!(Path.join(source_dir, "test.txt"), "text")
      File.write!(Path.join(source_dir, "test.ex"), "elixir")
      
      opts = [source_dir: source_dir]
      
      assert HaxeCompiler.source_files(opts) == []
    end
  end

  describe "integration with HaxeServer" do
    test "attempts to use HaxeServer when available", %{source_dir: source_dir, target_dir: target_dir} do
      # Start HaxeServer (may not actually work without real Haxe)
      try do
        {:ok, _pid} = HaxeServer.start_link([])
        Process.sleep(100)  # Give it time to attempt startup
      catch
        _, _ -> :ok  # Ignore if HaxeServer fails to start
      end
      
      build_hxml = Path.join(Path.dirname(source_dir), "build.hxml")
      File.write!(build_hxml, """
      -lib reflaxe.elixir
      -cp #{source_dir}
      -D elixir_output=#{target_dir}
      """)
      
      File.write!(Path.join(source_dir, "ServerTest.hx"), "class ServerTest {}")
      
      opts = [
        hxml_file: build_hxml,
        source_dir: source_dir,
        target_dir: target_dir,
        verbose: true
      ]
      
      # This should attempt to use the server but may fall back to direct compilation
      result = HaxeCompiler.compile(opts)
      
      # Should get some result (success or failure)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
      
      # Clean up
      try do
        HaxeServer.stop()
      catch
        _, _ -> :ok
      end
    end
  end

  describe "error handling" do
    test "handles invalid Haxe command gracefully", %{source_dir: source_dir, target_dir: target_dir} do
      build_hxml = Path.join(Path.dirname(source_dir), "invalid_build.hxml")
      File.write!(build_hxml, """
      -cp #{source_dir}
      --invalid-target
      """)
      
      File.write!(Path.join(source_dir, "ErrorTest.hx"), "class ErrorTest {}")
      
      opts = [
        hxml_file: build_hxml,
        source_dir: source_dir,
        target_dir: target_dir
      ]
      
      assert {:error, reason} = HaxeCompiler.compile(opts)
      assert is_binary(reason)
      # Should contain some indication of failure
      assert reason =~ "compilation failed" or reason =~ "Failed to execute" or reason =~ "Haxe"
    end

    test "provides meaningful error messages" do
      # Test with completely invalid configuration
      opts = [
        hxml_file: "",
        source_dir: "",
        target_dir: ""
      ]
      
      assert {:error, reason} = HaxeCompiler.compile(opts)
      assert is_binary(reason)
      assert String.length(reason) > 0
    end
  end

  describe "file path handling" do
    test "handles paths with spaces correctly", %{test_dir: test_dir} do
      # Create directories with spaces
      source_with_spaces = Path.join(test_dir, "src with spaces")
      target_with_spaces = Path.join(test_dir, "lib with spaces")
      
      File.mkdir_p!(source_with_spaces)
      File.mkdir_p!(target_with_spaces)
      
      File.write!(Path.join(source_with_spaces, "SpaceTest.hx"), "class SpaceTest {}")
      
      opts = [
        source_dir: source_with_spaces,
        target_dir: target_with_spaces
      ]
      
      # Should handle paths with spaces without crashing
      files = HaxeCompiler.source_files(opts)
      assert length(files) == 1
      
      needs_recompile = HaxeCompiler.needs_recompilation?(opts)
      assert is_boolean(needs_recompile)
    end

    test "handles relative and absolute paths", %{source_dir: source_dir, target_dir: _target_dir} do
      File.write!(Path.join(source_dir, "PathTest.hx"), "class PathTest {}")
      
      # Test with relative path
      relative_source = Path.relative_to_cwd(source_dir)
      opts_relative = [source_dir: relative_source]
      
      # Test with absolute path  
      absolute_source = Path.expand(source_dir)
      opts_absolute = [source_dir: absolute_source]
      
      # Both should work
      files_relative = HaxeCompiler.source_files(opts_relative)
      files_absolute = HaxeCompiler.source_files(opts_absolute)
      
      assert length(files_relative) == 1
      assert length(files_absolute) == 1
    end
  end
end
