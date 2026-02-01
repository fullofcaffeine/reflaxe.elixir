# Test environment setup
# Set up paths for Haxe compiler
System.put_env("HAXE_PATH", System.find_executable("haxe") || "haxe")
System.put_env("NPX_PATH", System.find_executable("npx") || "npx")

# Set HAXELIB_PATH to project's haxe_libraries for test environments
project_root = Path.expand(Path.join([__DIR__, "../.."]))
haxe_libraries_path = Path.join(project_root, "haxe_libraries")
System.put_env("HAXELIB_PATH", haxe_libraries_path)

# Ensure test fixtures directory exists
File.mkdir_p!(Path.join(project_root, "test/fixtures"))

# Compile test support modules
Code.compile_file(Path.join(project_root, "test/support/haxe_test_helper.ex"))

# Compile + load Haxe-authored ExUnit tests (stdlib runtime semantics)
generated_dir = Path.join(project_root, "test/fixtures/_generated_haxe_exunit")
haxe_test_src = Path.join(project_root, "test/haxe_exunit/stdlib_parity/src_haxe")

if File.dir?(haxe_test_src) do
  File.rm_rf!(generated_dir)
  File.mkdir_p!(generated_dir)

  haxe_bin = System.get_env("HAXE_PATH") || "haxe"
  timeout_script = Path.join(project_root, "scripts/with-timeout.sh")

  {output, status} =
    System.cmd(timeout_script, [
      "--secs",
      "240",
      "--",
      haxe_bin,
      "-cp",
      haxe_test_src,
      "-lib",
      "reflaxe.elixir",
      "-dce",
      "full",
      "-D",
      "reflaxe_runtime",
      "-D",
      "elixir_output=#{generated_dir}",
      "stdlib_parity.StdlibParityTest"
    ], cd: project_root, stderr_to_stdout: true)

  if status != 0 do
    raise """
    Failed to compile Haxe-authored ExUnit tests (status=#{status}).

    Output:
    #{output}
    """
  end

  ExUnit.start()

  generated_dir
  |> Path.join("**/*.ex")
  |> Path.wildcard()
  |> Enum.sort()
  |> Enum.each(&Code.require_file/1)
else
  ExUnit.start()
end

# Configure ExUnit for parallel execution (default: 2x CPU cores)
# Tests with async: false will still run sequentially as needed
# Remove max_cases limitation to enable default parallel execution

# Note: ExUnit is started above, before requiring generated test modules.
