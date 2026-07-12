# Test environment setup
# Set HAXELIB_PATH to project's haxe_libraries for test environments
project_root = Path.expand(Path.join([__DIR__, "../.."]))
haxe_libraries_path = Path.join(project_root, "haxe_libraries")
System.put_env("HAXELIB_PATH", haxe_libraries_path)

# Prefer a real lix-managed Haxe binary over any Node-based shim.
#
# Why:
# - `System.find_executable("haxe")` can resolve to an npm-installed wrapper (or other Node shim)
#   that may hang or be incompatible with `scripts/with-timeout.sh`.
# - The project pins a Haxe toolchain via `.haxerc` + lix; use that when possible so CI and local
#   behavior match.
haxe_hint =
  cond do
    is_binary(System.get_env("HAXE_PATH")) and File.exists?(System.get_env("HAXE_PATH")) ->
      System.get_env("HAXE_PATH")

    File.exists?(Path.join([project_root, "node_modules", ".bin", "haxe"])) ->
      Path.join([project_root, "node_modules", ".bin", "haxe"])

    true ->
      System.find_executable("haxe") || "haxe"
  end

{resolved_haxe, _args} = HaxeServer.resolve_haxe_cmd(haxe_hint, [], project_root)
System.put_env("HAXE_PATH", resolved_haxe)

# Prefer deterministic, non-leaky test runs: never auto-start `haxe --wait` server in ExUnit.
System.put_env("HAXE_NO_SERVER", "1")

# Set up paths for helper tooling
System.put_env("NPX_PATH", System.find_executable("npx") || "npx")

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
  bash_bin = System.find_executable("bash") || "bash"

  haxe_test_modules = [
    "stdlib_parity.StdlibParityTest",
    "stdlib_parity.UpstreamUnitStdTest"
  ]

  {output, status} =
    System.cmd(bash_bin, [
      timeout_script,
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
      "elixir_output=#{generated_dir}"
    ] ++ haxe_test_modules, cd: project_root, stderr_to_stdout: true)

  if status != 0 do
    raise """
    Failed to compile Haxe-authored ExUnit modules #{Enum.join(haxe_test_modules, ", ")} (status=#{status}).

    Output:
    #{output}
    """
  end

  ExUnit.start()

  ex_files =
    generated_dir
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, generated_dir))
    |> Enum.sort()

  # Dependency-friendly load order: require core runtime modules (like `Reflaxe.Elixir.HaxeThrow`)
  # before stdlib stubs that reference them.
  prefer = [
    "reflaxe/exception.ex",
    "reflaxe/elixir/haxe_throw.ex",
    "reflaxe/elixir/haxe_float.ex",
    "type.ex",
    "reflect.ex",
    "std.ex",
    "string_tools.ex",
    "string_buf.ex",
    "sys.ex",
    "haxe/exceptions/pos_exception.ex",
    "haxe/exceptions/not_implemented_exception.ex",
    "haxe/io/eof.ex",
    "haxe/io/bytes.ex",
    "haxe/io/output.ex",
    "haxe/io/bytes_input.ex",
    "haxe/io/bytes_output.ex"
  ]

  {preferred, remaining} = Enum.split_with(ex_files, fn rel -> rel in prefer end)

  preferred =
    prefer
    |> Enum.filter(&(&1 in preferred))

  {reflaxe, remaining} = Enum.split_with(remaining, &String.starts_with?(&1, "reflaxe/"))
  {haxe, remaining} = Enum.split_with(remaining, &String.starts_with?(&1, "haxe/"))

  ordered = preferred ++ reflaxe ++ haxe ++ remaining

  Enum.each(ordered, fn rel ->
    Code.require_file(Path.join(generated_dir, rel))
  end)
else
  ExUnit.start()
end

# Configure ExUnit for parallel execution (default: 2x CPU cores)
# Tests with async: false will still run sequentially as needed
# Remove max_cases limitation to enable default parallel execution

# Note: ExUnit is started above, before requiring generated test modules.
