defmodule Mix.Tasks.Haxe.SourceMapTaskTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @project_root Path.expand("../..", __DIR__)
  @fixture_dir Path.join(@project_root, "test/snapshot/core/source_map_basic")
  @out_dir Path.join(@fixture_dir, "out")
  @generated_ex Path.join(@out_dir, "source_map_test.ex")
  @generated_map Path.join(@out_dir, "source_map_test.ex.map")
  @haxe_file Path.join(@fixture_dir, "SourceMapTest.hx")

  setup do
    File.rm_rf!(@out_dir)

    {out, status} =
      System.cmd("haxe", ["compile.hxml", "-D", "source_map_enabled"], cd: @fixture_dir, stderr_to_stdout: true)

    assert status == 0, "haxe compile failed:\n#{out}"
    assert File.exists?(@generated_ex), "expected generated file to exist: #{@generated_ex}"
    assert File.exists?(@generated_map), "expected source map to exist: #{@generated_map}"

    :ok
  end

  test "reverse lookup auto-detects .hx and finds the generated file" do
    output =
      capture_io(fn ->
        Mix.Tasks.Haxe.SourceMap.run([@haxe_file, "7", "4", "--target-dir", @out_dir])
      end)

    assert output =~ "Generated Elixir"
    assert output =~ "source_map_test.ex"
    assert String.contains?(output, "✅ Exact match") or String.contains?(output, "Approximate match")
  end
end
