defmodule HaxeTestHelper do
  @moduledoc """
  Helper functions for setting up Haxe test environments.
  
  This module provides utilities to create valid test projects that can
  successfully compile Haxe code using the reflaxe.elixir compiler.
  """
  
  @doc """
  Sets up a complete test project with all necessary files and configurations.
  
  ## Options
    * `:dir` - The directory to set up (required)
    * `:create_hxml` - Whether to create a build.hxml file (default: true)
    * `:link_libraries` - Whether to symlink haxe_libraries (default: true)
  """
  def setup_test_project(opts) do
    dir = Keyword.fetch!(opts, :dir)
    create_hxml = Keyword.get(opts, :create_hxml, true)
    link_libraries = Keyword.get(opts, :link_libraries, true)
    
    # Ensure directory exists
    File.mkdir_p!(dir)
    
    # Create source directory
    src_dir = Path.join(dir, "src_haxe")
    File.mkdir_p!(src_dir)
    
    # Create output directory
    out_dir = Path.join(dir, "lib")
    File.mkdir_p!(out_dir)
    
    # Link or copy haxe_libraries
    if link_libraries do
      setup_haxe_libraries(dir)
    end
    
    # Create default build.hxml if requested
    if create_hxml do
      create_build_hxml(dir)
    end
    
    :ok
  end
  
  @doc """
  Creates or links haxe_libraries directory in the test project.
  """
  def setup_haxe_libraries(project_dir) do
    # Find the project root by looking for mix.exs
    project_root = find_project_root()
    source_libraries = Path.expand(Path.join(project_root, "haxe_libraries"))
    target_libraries = Path.expand(Path.join(project_dir, "haxe_libraries"))
    
    # Set HAXELIB_PATH environment variable for test processes
    # This is critical for Haxe to find the libraries when using -lib directive
    System.put_env("HAXELIB_PATH", target_libraries)
    
    # Remove existing link/directory if it exists
    if File.exists?(target_libraries) do
      File.rm_rf!(target_libraries)
    end
    
    # Create symlink to the main haxe_libraries
    case :file.make_symlink(
      String.to_charlist(source_libraries),
      String.to_charlist(target_libraries)
    ) do
      :ok -> 
        # Also set the environment variable to point to the symlinked directory
        System.put_env("HAXELIB_PATH", target_libraries)
        :ok
      {:error, :enotsup} ->
        # Fallback to copying if symlinks not supported
        File.cp_r!(source_libraries, target_libraries)
        System.put_env("HAXELIB_PATH", target_libraries)
        :ok
      {:error, reason} ->
        raise "Failed to link haxe_libraries: #{inspect(reason)}"
    end
    
    # NOTE: We avoid symlinking src/ and std/ directories as it causes the "35-file phenomenon"
    # where standard library files get compiled unintentionally. The haxe_libraries symlink
    # should be sufficient for most test scenarios. If specific tests need these directories,
    # they should set them up explicitly.
    #
    # The reflaxe.elixir.hxml library file should handle compilation properly without
    # requiring direct access to src/ and std/ directories in test environments.
    
    :ok
  end
  
  @doc """
  Creates a basic build.hxml file for the test project.
  """
  def create_build_hxml(project_dir, opts \\ []) do
    main_class = Keyword.get(opts, :main_class, "Main")
    source_dir = Keyword.get(opts, :source_dir, "src_haxe")
    output_dir = Keyword.get(opts, :output_dir, "lib")
    
    hxml_content = """
    # Test project build configuration
    -cp #{source_dir}
    -lib reflaxe.elixir
    -D reflaxe_runtime
    -D elixir_output=#{output_dir}
    #{main_class}
    """
    
    hxml_path = Path.join(project_dir, "build.hxml")
    File.write!(hxml_path, hxml_content)
  end
  
  @doc """
  Creates a simple Haxe source file for testing.
  """
  def create_test_haxe_file(project_dir, opts \\ []) do
    filename = Keyword.get(opts, :filename, "Main.hx")
    content = Keyword.get(opts, :content, default_haxe_content())
    
    file_path = Path.join([project_dir, "src_haxe", filename])
    File.write!(file_path, content)
  end
  
  @doc """
  Creates a Haxe file with a compilation error for error handling tests.
  """
  def create_error_haxe_file(project_dir, opts \\ []) do
    filename = Keyword.get(opts, :filename, "ErrorTest.hx")
    error_type = Keyword.get(opts, :error_type, :syntax)
    
    content = case error_type do
      :syntax -> """
      class ErrorTest {
        public static function main() {
          var x = "unclosed string
        }
      }
      """
      
      :type -> """
      class ErrorTest {
        public static function main() {
          var x: Int = "not an int";
        }
      }
      """
      
      :undefined -> """
      class ErrorTest {
        public static function main() {
          unknownFunction();
        }
      }
      """
      
      _ -> """
      class ErrorTest {
        // This will cause an error
        public static function main() {
      }
      """
    end
    
    file_path = Path.join([project_dir, "src_haxe", filename])
    File.write!(file_path, content)
  end
  
  @doc """
  Ensures that npx and haxe are available in the test environment.
  """
  def ensure_haxe_available do
    cond do
      System.find_executable("npx") != nil ->
        # Try npx haxe
        case System.cmd("npx", ["haxe", "--version"], stderr_to_stdout: true) do
          {_output, 0} -> {:ok, :npx}
          _ -> check_direct_haxe()
        end
      
      true ->
        check_direct_haxe()
    end
  end
  
  defp check_direct_haxe do
    cond do
      System.find_executable("haxe") != nil ->
        {:ok, :direct}
      
      File.exists?("/opt/homebrew/bin/haxe") ->
        {:ok, :homebrew}
      
      true ->
        {:error, "Haxe not found"}
    end
  end
  
  defp default_haxe_content do
    """
    class Main {
      public static function main() {
        trace("Hello from Haxe test!");
      }
      
      public static function add(a: Int, b: Int): Int {
        return a + b;
      }
    }
    """
  end
  
  @doc """
  Cleans up a test project directory.
  """
  def cleanup_test_project(dir) do
    if File.exists?(dir) do
      File.rm_rf!(dir)
    end
  end
  
  defp find_project_root(path \\ File.cwd!()) do
    if File.exists?(Path.join(path, "mix.exs")) do
      path
    else
      parent = Path.dirname(path)
      if parent == path do
        # Reached root without finding mix.exs
        raise "Could not find project root (mix.exs not found)"
      else
        find_project_root(parent)
      end
    end
  end
end