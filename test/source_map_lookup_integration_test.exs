defmodule SourceMapLookupIntegrationTest do
  use ExUnit.Case, async: false

  @fixture_dir Path.expand("snapshot/core/source_map_basic", __DIR__)
  @out_dir Path.join(@fixture_dir, "out")
  @generated_ex Path.join(@out_dir, "source_map_test.ex")
  @generated_map Path.join(@out_dir, "source_map_test.ex.map")

  test "source maps emit and lookup returns real Haxe positions" do
    File.rm_rf!(@out_dir)

    {out, status} =
      System.cmd("haxe", ["compile.hxml", "-D", "source_map_enabled"], cd: @fixture_dir, stderr_to_stdout: true)

    assert status == 0, "haxe compile failed:\n#{out}"
    assert File.exists?(@generated_ex), "expected generated file to exist: #{@generated_ex}"
    assert File.exists?(@generated_map), "expected source map to exist: #{@generated_map}"

    {:ok, source_map} = SourceMapLookup.parse_source_map(@generated_map)

    generated_lines =
      @generated_ex
      |> File.read!()
      |> String.split("\n", trim: false)

    assert_haxe_line(source_map, generated_lines, "def simple_method", "SourceMapTest.hx", 7)
    assert_haxe_line(source_map, generated_lines, "def conditional_method", "SourceMapTest.hx", 11)
    assert_haxe_line(source_map, generated_lines, "def main", "SourceMapTest.hx", 19)
  end

  defp assert_haxe_line(source_map, generated_lines, marker, expected_file, expected_line) do
    gen_line =
      generated_lines
      |> Enum.find_index(fn line -> String.contains?(line, marker) end)
      |> case do
        nil -> flunk("could not find #{inspect(marker)} in generated output")
        idx -> idx + 1
      end

    {:ok, mapped} = SourceMapLookup.lookup_haxe_position(source_map, gen_line, 0)

    assert Path.basename(mapped.file) == expected_file
    assert mapped.line == expected_line
  end
end

