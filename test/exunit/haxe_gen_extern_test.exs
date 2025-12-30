defmodule Mix.Tasks.Haxe.Gen.ExternTest do
  use ExUnit.Case, async: true

  test "generates a starter extern with overloads" do
    tmp_root = Path.join(System.tmp_dir!(), "haxe_gen_extern_#{System.unique_integer([:positive])}")
    out_dir = Path.join(tmp_root, "src_haxe/externs")

    File.mkdir_p!(out_dir)

    Mix.Tasks.Haxe.Gen.Extern.run([
      "Enum",
      "--out",
      out_dir,
      "--package",
      "externs.test"
    ])

    file_path = Path.join(out_dir, "Enum.hx")
    contents = File.read!(file_path)

    assert contents =~ ~s(package externs.test;)
    assert contents =~ ~s|@:native("Enum")|
    assert contents =~ "extern class Enum"

    # Enum has multiple arities for common functions (e.g. all?/1 and all?/2),
    # which should produce @:overload metadata in the generated extern.
    assert contents =~ "@:overload"
    assert contents =~ "public static function allQ"
  end
end
