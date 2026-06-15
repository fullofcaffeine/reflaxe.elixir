defmodule HaxeExUnitStdlibRuntimeHarnessTest do
  use ExUnit.Case, async: false

  @project_root Path.expand(Path.join([__DIR__, "../.."]))
  @generated_dir Path.join(@project_root, "test/fixtures/_generated_haxe_exunit")

  test "stdlib parity Haxe ExUnit suite is generated and loaded" do
    generated_parity_test = Path.join(@generated_dir, "stdlib_parity/stdlib_parity_test.ex")
    generated_upstream_test = Path.join(@generated_dir, "stdlib_parity/upstream_unit_std_test.ex")

    assert File.exists?(generated_parity_test)
    assert File.exists?(generated_upstream_test)
    assert Code.ensure_loaded?(StdlibParityTest)
    assert Code.ensure_loaded?(UpstreamUnitStdTest)
  end
end
