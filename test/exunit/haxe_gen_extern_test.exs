defmodule Mix.Tasks.Haxe.Gen.ExternTest do
  use ExUnit.Case, async: true

  test "generates a starter extern with overloads" do
    tmp_root = tmp_root()
    out_dir = Path.join(tmp_root, "src_haxe/externs")
    on_exit(fn -> File.rm_rf!(tmp_root) end)

    File.mkdir_p!(out_dir)

    Mix.Tasks.Haxe.Gen.Extern.run([
      "Enum",
      "--out",
      out_dir,
      "--package",
      "externs.test"
    ])

    file_path = Path.join([out_dir, "test", "Enum.hx"])
    contents = File.read!(file_path)

    assert contents =~ ~s(package externs.test;)
    assert contents =~ ~s|@:native("Enum")|
    assert contents =~ ~s|@:unsafeExtern|
    assert contents =~ "extern class Enum"
    refute contents =~ "Dynamic"

    # Enum has multiple arities for common functions (e.g. all?/1 and all?/2),
    # which should produce @:overload metadata in the generated extern.
    assert contents =~ "@:overload"
    assert contents =~ "public static function allQ"
  end

  test "generates an Erlang module extern from module_info exports" do
    tmp_root = tmp_root()
    out_dir = Path.join(tmp_root, "src_haxe/externs")
    on_exit(fn -> File.rm_rf!(tmp_root) end)

    File.mkdir_p!(out_dir)

    Mix.Tasks.Haxe.Gen.Extern.run([
      ":crypto",
      "--out",
      out_dir,
      "--package",
      "externs.erlang"
    ])

    file_path = Path.join([out_dir, "erlang", "Crypto.hx"])
    contents = File.read!(file_path)

    assert contents =~ ~s(package externs.erlang;)
    assert contents =~ ~s|@:native(":crypto")|
    assert contents =~ "extern class Crypto"
    assert contents =~ "public static function supports"
    refute contents =~ "moduleInfo"
    refute contents =~ "Dynamic"
  end

  test "generates optional wrapper decoder and test pointer scaffolds" do
    tmp_root = tmp_root()
    out_dir = Path.join(tmp_root, "src_haxe/externs")
    on_exit(fn -> File.rm_rf!(tmp_root) end)

    File.mkdir_p!(out_dir)

    Mix.Tasks.Haxe.Gen.Extern.run([
      "Enum",
      "--out",
      out_dir,
      "--package",
      "externs.scaffold",
      "--wrapper",
      "--decoder",
      "--test-pointer"
    ])

    package_dir = Path.join([out_dir, "scaffold"])
    wrapper = File.read!(Path.join(package_dir, "EnumWrapper.hx"))
    decoder = File.read!(Path.join(package_dir, "EnumDecoder.hx"))
    test_pointer = File.read!(Path.join(package_dir, "EnumInteropTest.md"))

    assert wrapper =~ ~s(package externs.scaffold;)
    assert wrapper =~ "class EnumWrapper"
    assert wrapper =~ "return Enum.allQ"
    refute wrapper =~ "Dynamic"

    assert decoder =~ ~s(package externs.scaffold;)
    assert decoder =~ "import elixir.types.TermDecoder;"
    assert decoder =~ "import elixir.types.TermDecoder.TermDecodeError;"
    assert decoder =~ "class EnumDecoder"
    assert decoder =~ "Result<Array<Term>, TermDecodeError>"
    refute decoder =~ "Dynamic"

    assert test_pointer =~ "test_haxe/externs/EnumInteropTest.hx"
    assert test_pointer =~ "docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md"
    assert test_pointer =~ "@:exunit"
  end

  defp tmp_root do
    Path.join(System.tmp_dir!(), "haxe_gen_extern_#{System.unique_integer([:positive])}")
  end
end
