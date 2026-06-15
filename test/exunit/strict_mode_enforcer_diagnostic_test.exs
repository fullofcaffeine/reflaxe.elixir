defmodule StrictModeEnforcerDiagnosticTest do
  use ExUnit.Case, async: false

  test "ad-hoc extern diagnostic points to boundary scaffold" do
    haxe_bin =
      case HaxeTestHelper.ensure_haxe_available() do
        {:ok, _} ->
          System.find_executable("haxe") ||
            Path.join([HaxeTestHelper.find_project_root(), "node_modules", ".bin", "haxe"])

        {:error, reason} ->
          flunk("Haxe not available in test environment: #{reason}")
      end

    previous_haxelib_path = System.get_env("HAXELIB_PATH")

    tmp_root =
      Path.join(System.tmp_dir!(), "strict_mode_diag_#{System.unique_integer([:positive])}")

    on_exit(fn ->
      case previous_haxelib_path do
        nil -> System.delete_env("HAXELIB_PATH")
        value -> System.put_env("HAXELIB_PATH", value)
      end

      File.rm_rf!(tmp_root)
    end)

    HaxeTestHelper.setup_test_project(dir: tmp_root, create_hxml: false)

    File.write!(
      Path.join([tmp_root, "src_haxe", "StrictExternDiagnostic.hx"]),
      """
      extern class BadExtern {}

      class StrictExternDiagnostic {
        static function main() {}
      }
      """
    )

    File.write!(
      Path.join(tmp_root, "build.hxml"),
      """
      -cp src_haxe
      -lib reflaxe.elixir
      -D reflaxe_elixir_strict
      -D elixir_output=lib
      --no-output
      --main StrictExternDiagnostic
      """
    )

    {output, exit_status} =
      System.cmd(haxe_bin, ["build.hxml"], cd: tmp_root, stderr_to_stdout: true)

    assert exit_status != 0
    assert output =~ "Strict mode forbids ad-hoc `extern class` declarations"
    assert output =~ "mix haxe.gen.extern MyApp.Module --boundary"
    assert output =~ ~s|@:native("MyApp.Module") @:unsafeExtern extern class Module {}|
  end
end
