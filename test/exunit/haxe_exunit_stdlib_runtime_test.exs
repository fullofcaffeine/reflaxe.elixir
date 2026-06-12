defmodule HaxeExUnitStdlibRuntimeHarnessTest do
  use ExUnit.Case, async: false

  @project_root Path.expand(Path.join([__DIR__, "../.."]))
  @generated_dir Path.join(@project_root, "test/fixtures/_generated_haxe_exunit")

  test "stdlib parity Haxe ExUnit suite is generated and loaded" do
    generated_test = Path.join(@generated_dir, "stdlib_parity/stdlib_parity_test.ex")

    assert File.exists?(generated_test)
    assert Code.ensure_loaded?(StdlibParityTest)
  end
end
