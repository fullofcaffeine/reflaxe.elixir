defmodule Main do
  @moduledoc """
    Main struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_unused_parameters(5, "test", true)

    Main.callback_example(fn x, y -> x end)
  end

  @doc "Generated from Haxe testUnusedParameters"
  def test_unused_parameters(used1, _unused, used2) do
    if used2 do
      (used1 * 2)
    else
      nil
    end

    used1
  end

  @doc "Generated from Haxe callbackExample"
  def callback_example(callback) do
    callback.(42, "ignored")
  end

  @doc "Generated from Haxe fullyUnused"
  def fully_unused(_x, _y, _z) do
    "constant"
  end

  # Instance functions
  @doc "Generated from Haxe instanceMethod"
  def instance_method(%__MODULE__{} = struct, used, _unused1, _unused2) do
    (used + 10)
  end

end
