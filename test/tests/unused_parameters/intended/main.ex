defmodule Main do
  @moduledoc """
    Main struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
          Main.test_unused_parameters(5, "test", true)
          Main.callback_example(fn x, y -> x end)
        )
  end

  @doc "Function test_unused_parameters"
  @spec test_unused_parameters(integer(), String.t(), boolean()) :: integer()
  def test_unused_parameters(used1, _unused, used2) do
    (
          if used2 do
          (used1 * 2)
        end
          used1
        )
  end

  @doc "Function callback_example"
  @spec callback_example(Function.t()) :: integer()
  def callback_example(callback) do
    callback.(42, "ignored")
  end

  @doc "Function fully_unused"
  @spec fully_unused(integer(), String.t(), boolean()) :: String.t()
  def fully_unused(_x, _y, _z) do
    "constant"
  end

  # Instance functions
  @doc "Function instance_method"
  @spec instance_method(t(), integer(), String.t(), boolean()) :: integer()
  def instance_method(%__MODULE__{} = struct, used, _unused1, _unused2) do
    (used + 10)
  end

end
