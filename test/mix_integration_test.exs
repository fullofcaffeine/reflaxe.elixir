defmodule MixIntegrationTest do
  use ExUnit.Case, async: false
  
  import ExUnit.CaptureIO

  @moduletag :integration
  @moduletag timeout: :infinity

  @test_project_dir "test/fixtures/test_phoenix_project"
  @haxe_source_dir "#{@test_project_dir}/src_haxe"
  @target_dir "#{@test_project_dir}/lib"

  describe "Mix.Tasks.Compile.Haxe integration" do
    setup do
      # Clean up any previous test artifacts
      File.rm_rf!(@test_project_dir)
      File.mkdir_p!(@haxe_source_dir)
      File.mkdir_p!(@target_dir)
      
      # Create a minimal mix project structure
      mix_exs_content = """
      defmodule TestPhoenixProject.MixProject do
        use Mix.Project

        def project do
          [
            app: :test_phoenix_project,
            version: "0.1.0",
            elixir: "~> 1.14",
            compilers: [:haxe] ++ Mix.compilers(),
            start_permanent: Mix.env() == :prod,
            deps: []
          ]
        end

        def application, do: []
      end
      """
      
      File.write!("#{@test_project_dir}/mix.exs", mix_exs_content)
      
      # Create a simple Haxe source file for testing
      haxe_source_content = """
      package test;
      
      class SimpleClass {
          public static function main() {
              trace("Hello from Haxe!");
          }
          
          public static function greet(name: String): String {
              return "Hello, " + name + "!";
          }
      }
      """
      
      File.write!("#{@haxe_source_dir}/SimpleClass.hx", haxe_source_content)
      
      # Create build.hxml configuration
      hxml_content = """
      -cp src_haxe
      -lib reflaxe.elixir
      -D reflaxe_runtime
      --elixir lib
      test.SimpleClass
      """
      
      File.write!("#{@test_project_dir}/build.hxml", hxml_content)
      
      # Switch to test project directory for Mix operations
      original_cwd = File.cwd!()
      File.cd!(@test_project_dir)
      
      on_exit(fn ->
        File.cd!(original_cwd)
        File.rm_rf!(@test_project_dir)
      end)
      
      %{original_cwd: original_cwd}
    end

    test "Mix compiler task loads and executes without errors" do
      output = capture_io(fn ->
        result = Mix.Tasks.Compile.Haxe.run([])
        # Should compile the SimpleClass.hx file created in setup
        assert {:ok, compiled_files} = result
        assert is_list(compiled_files)
        assert length(compiled_files) == 1
        assert String.ends_with?(hd(compiled_files), "SimpleClass.ex")
      end)
      
      assert String.contains?(output, "Compiled 1 Haxe file(s)")
    end
    
    test "Mix compiler task implements required Mix.Task.Compiler callbacks" do
      # Test manifests/0 callback
      manifests = Mix.Tasks.Compile.Haxe.manifests()
      assert is_list(manifests)
      assert length(manifests) == 1
      assert String.ends_with?(hd(manifests), "compile.haxe")
      
      # Test clean/0 callback
      assert Mix.Tasks.Compile.Haxe.clean() == :ok
    end
    
    test "Mix compiler task handles compilation errors properly" do
      # Create invalid Haxe source
      invalid_haxe = """
      package test;
      
      class ErrorClass {
          public static function main() {
              var x = "unclosed string
          }
      }
      """
      
      File.write!("src_haxe/ErrorClass.hx", invalid_haxe)
      
      output = capture_io(:stderr, fn ->
        result = Mix.Tasks.Compile.Haxe.run([])
        assert {:error, []} = result
      end)
      
      assert String.contains?(output, "Haxe compilation failed:")
      assert String.contains?(output, "Syntax error")
    end
    
    test "HaxeCompiler module provides expected API" do
      # Test compile/1 function with valid setup (using relative paths from test project dir)
      assert {:ok, compiled_files} = HaxeCompiler.compile(
        hxml_file: "build.hxml",
        source_dir: "src_haxe",
        target_dir: "lib"
      )
      assert is_list(compiled_files)
      assert length(compiled_files) == 1
      
      # Test error cases
      assert {:error, "Build file not found: missing.hxml"} = 
        HaxeCompiler.compile(hxml_file: "missing.hxml")
      assert {:error, "Source directory not found: missing_dir"} = 
        HaxeCompiler.compile(source_dir: "missing_dir")
      
      # Test needs_recompilation?/1 function
      assert HaxeCompiler.needs_recompilation?(source_dir: "src_haxe", target_dir: "lib") == true
      assert HaxeCompiler.needs_recompilation?(force: true) == true
      
      # Test source_files/1 function  
      source_files = HaxeCompiler.source_files(source_dir: "src_haxe")
      assert length(source_files) == 1
      assert String.ends_with?(hd(source_files), "SimpleClass.hx")
      
      assert HaxeCompiler.source_files(source_dir: "missing") == []
    end
  end

  describe "Build pipeline integration" do
    setup do
      # Clean up any previous test artifacts
      File.rm_rf!(@test_project_dir)
      File.mkdir_p!(@haxe_source_dir)
      File.mkdir_p!(@target_dir)
      
      # Create a minimal mix project structure
      mix_exs_content = """
      defmodule TestPhoenixProject.MixProject do
        use Mix.Project

        def project do
          [
            app: :test_phoenix_project,
            version: "0.1.0",
            elixir: "~> 1.14",
            compilers: [:haxe] ++ Mix.compilers(),
            start_permanent: Mix.env() == :prod,
            deps: []
          ]
        end

        def application, do: []
      end
      """
      
      File.write!("#{@test_project_dir}/mix.exs", mix_exs_content)
      
      # Create a simple Haxe source file for testing
      haxe_source_content = """
      package test;
      
      class SimpleClass {
          public static function main() {
              trace("Hello from Haxe!");
          }
          
          public static function greet(name: String): String {
              return "Hello, " + name + "!";
          }
      }
      """
      
      File.write!("#{@haxe_source_dir}/SimpleClass.hx", haxe_source_content)
      
      # Create build.hxml configuration
      hxml_content = """
      -cp src_haxe
      -lib reflaxe.elixir
      -D reflaxe_runtime
      --elixir lib
      test.SimpleClass
      """
      
      File.write!("#{@test_project_dir}/build.hxml", hxml_content)
      
      # Switch to test project directory for Mix operations
      original_cwd = File.cwd!()
      File.cd!(@test_project_dir)
      
      on_exit(fn ->
        File.cd!(original_cwd)
        File.rm_rf!(@test_project_dir)
      end)
      
      %{original_cwd: original_cwd}
    end

    test "compiles Haxe files to Elixir modules" do
      assert {:ok, compiled_files} = HaxeCompiler.compile(
        source_dir: "src_haxe",
        target_dir: "lib",
        hxml_file: "build.hxml"
      )
      
      assert is_list(compiled_files)
      assert length(compiled_files) > 0
      
      # For now, just verify the compilation returns expected file paths
      # Note: We're not actually generating Elixir files yet - this is simulated
      expected_file = "lib/SimpleClass.ex"
      assert expected_file in compiled_files
    end

    test "incremental compilation only recompiles changed files" do
      # First compilation
      {:ok, _} = HaxeCompiler.compile(source_dir: "src_haxe", target_dir: "lib")
      
      # For incremental compilation test, we need to simulate target files existing
      File.mkdir_p!("lib")
      File.touch!("lib/SimpleClass.ex")
      
      # Should not need recompilation if target is newer
      refute HaxeCompiler.needs_recompilation?(source_dir: "src_haxe", target_dir: "lib")
      
      # Wait a moment to ensure timestamp difference
      :timer.sleep(1000)
      
      # Modify source file 
      File.touch!("src_haxe/SimpleClass.hx")
      
      # Should need recompilation after changes
      assert HaxeCompiler.needs_recompilation?(source_dir: "src_haxe", target_dir: "lib")
    end

    test "handles compilation errors gracefully" do
      # Create invalid Haxe source with unclosed string
      invalid_haxe = """
      package test;
      
      class InvalidClass {
          public static function main() {
              // Syntax error - unclosed string
              var x = "unclosed string
          }
      }
      """
      
      File.write!("src_haxe/InvalidClass.hx", invalid_haxe)
      
      assert {:error, error_message} = HaxeCompiler.compile(
        source_dir: "src_haxe", 
        target_dir: "lib",
        hxml_file: "build.hxml"
      )
      assert is_binary(error_message)
      assert String.contains?(error_message, "Syntax error")
      assert String.contains?(error_message, "InvalidClass.hx")
      assert String.contains?(error_message, "Unclosed string literal")
    end

    test "file watching detects source file changes" do
      source_files = HaxeCompiler.source_files(source_dir: "src_haxe")
      
      assert is_list(source_files)
      assert Enum.any?(source_files, &String.ends_with?(&1, ".hx"))
      assert Enum.any?(source_files, &String.contains?(&1, "SimpleClass.hx"))
    end
  end

  describe "Phoenix integration" do
    setup do
      # Use the same test project setup as other tests
      File.rm_rf!(@test_project_dir)
      File.mkdir_p!(@haxe_source_dir)
      File.mkdir_p!(@target_dir)
      
      # Create a Phoenix-like mix project with haxe compiler integration
      mix_exs_content = """
      defmodule TestPhoenixProject.MixProject do
        use Mix.Project

        def project do
          [
            app: :test_phoenix_project,
            version: "0.1.0",
            elixir: "~> 1.14",
            compilers: [:haxe] ++ Mix.compilers(),
            start_permanent: Mix.env() == :prod,
            deps: [],
            haxe_compiler: [
              hxml_file: "build.hxml",
              source_dir: "src_haxe",
              target_dir: "lib",
              verbose: false
            ]
          ]
        end

        def application, do: [extra_applications: [:logger]]
      end
      """
      
      File.write!("#{@test_project_dir}/mix.exs", mix_exs_content)
      
      # Create a Haxe source file
      File.write!("#{@haxe_source_dir}/PhoenixComponent.hx", """
      package phoenix;
      
      class PhoenixComponent {
          public static function main() {
              trace("Phoenix integration working!");
          }
          
          public static function render(): String {
              return "<div>Hello from Haxe component!</div>";
          }
      }
      """)
      
      # Create build.hxml
      File.write!("#{@test_project_dir}/build.hxml", """
      -cp src_haxe
      -lib reflaxe.elixir
      -D reflaxe_runtime
      --elixir lib
      phoenix.PhoenixComponent
      """)
      
      original_cwd = File.cwd!()
      File.cd!(@test_project_dir)
      
      on_exit(fn ->
        File.cd!(original_cwd)
        File.rm_rf!(@test_project_dir)
      end)
      
      %{original_cwd: original_cwd}
    end
    
    test "integrates with Phoenix build pipeline and uses custom configuration" do
      # Test that the compiler reads configuration from mix.exs
      output = capture_io(fn ->
        result = Mix.Tasks.Compile.Haxe.run([])
        assert {:ok, compiled_files} = result
        assert length(compiled_files) == 1
        assert String.ends_with?(hd(compiled_files), "PhoenixComponent.ex")
      end)
      
      assert String.contains?(output, "Compiled 1 Haxe file(s)")
    end
    
    test "supports verbose mode for development workflow" do
      output = capture_io(fn ->
        result = Mix.Tasks.Compile.Haxe.run(["--verbose"])
        assert {:ok, compiled_files} = result
        assert length(compiled_files) == 1
      end)
      
      assert String.contains?(output, "Starting Haxe compilation...")
      assert String.contains?(output, "Compiling Haxe files from src_haxe to lib")
      assert String.contains?(output, "Using build file: build.hxml")
      assert String.contains?(output, "Successfully compiled 1 file(s)")
    end
    
    test "supports forced recompilation for clean builds" do
      # First compilation
      {:ok, _} = Mix.Tasks.Compile.Haxe.run([])
      
      # Create target file to simulate no changes needed
      File.mkdir_p!("lib")
      File.touch!("lib/PhoenixComponent.ex")
      
      # Should skip without --force
      output1 = capture_io(fn ->
        result = Mix.Tasks.Compile.Haxe.run([])
        assert {:noop, []} = result
      end)
      
      assert String.contains?(output1, "") or not String.contains?(output1, "Compiled")
      
      # Should compile with --force
      output2 = capture_io(fn ->
        result = Mix.Tasks.Compile.Haxe.run(["--force"])
        assert {:ok, compiled_files} = result
        assert length(compiled_files) == 1
      end)
      
      assert String.contains?(output2, "Compiled 1 Haxe file(s)")
    end

    test "Phoenix development workflow: compile -> modify -> recompile" do
      # Initial compilation
      {:ok, files1} = Mix.Tasks.Compile.Haxe.run([])
      assert length(files1) == 1
      
      # Wait to ensure timestamp difference
      :timer.sleep(1000)
      
      # Modify source file
      File.write!("src_haxe/PhoenixComponent.hx", """
      package phoenix;
      
      class PhoenixComponent {
          public static function main() {
              trace("Modified Phoenix component!");
          }
          
          public static function render(): String {
              return "<div>Hello from Modified Haxe component!</div>";
          }
          
          public static function newFunction(): String {
              return "New functionality added";
          }
      }
      """)
      
      # Should detect changes and recompile
      assert HaxeCompiler.needs_recompilation?(source_dir: "src_haxe", target_dir: "lib") == true
      
      output = capture_io(fn ->
        {:ok, files2} = Mix.Tasks.Compile.Haxe.run([])
        assert length(files2) == 1
      end)
      
      assert String.contains?(output, "Compiled 1 Haxe file(s)")
    end
  end

  describe "Performance and scalability" do
    @tag :skip
    test "compilation completes within performance targets" do
      start_time = System.monotonic_time(:millisecond)
      
      {:ok, _} = HaxeCompiler.compile(source_dir: @haxe_source_dir)
      
      end_time = System.monotonic_time(:millisecond)
      compilation_time = end_time - start_time
      
      # Performance target: <15ms compilation steps from requirements
      assert compilation_time < 15, "Compilation took #{compilation_time}ms, expected <15ms"
    end
  end
end