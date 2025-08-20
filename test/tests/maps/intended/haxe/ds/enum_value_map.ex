defmodule EnumValueMap do
  @behaviour IMap

  @moduledoc """
    EnumValueMap struct generated from Haxe

      EnumValueMap allows mapping of enum value keys to arbitrary values.

      Keys are compared by value and recursively over their parameters. If any
      parameter is not an enum value, `Reflect.compare` is used to compare them.
  """

  # Instance functions
  @doc "Function compare"
  @spec compare(t(), EnumValue.t(), EnumValue.t()) :: integer()
  def compare(%__MODULE__{} = struct, k1, k2) do
    d = Type.enum_index(k1) - Type.enum_index(k2)
    if (d != 0), do: d, else: nil
    p1 = Type.enum_parameters(k1)
    p2 = Type.enum_parameters(k2)
    if (p1.length == 0 && p2.length == 0), do: 0, else: nil
    struct.compare_args(p1, p2)
  end

  @doc "Function compare_args"
  @spec compare_args(t(), Array.t(), Array.t()) :: integer()
  def compare_args(%__MODULE__{} = struct, a1, a2) do
    ld = a1.length - a2.length
    if (ld != 0), do: ld, else: nil
    _g_counter = 0
    _g_3 = Enum.count(a1)
    (
      loop_helper = fn loop_fn ->
        if (g < g) do
          i = g = g + 1
    d = struct.compareArg(Enum.at(a1, i), Enum.at(a2, i))
    if (d != 0), do: d, else: nil
          loop_fn.()
        else
          nil
        end
      end
      loop_helper.(loop_helper)
    )
    0
  end

  @doc "Function compare_arg"
  @spec compare_arg(t(), term(), term()) :: integer()
  def compare_arg(%__MODULE__{} = struct, v1, v2) do
    if ((Reflect.is_enum_value(v1) && Reflect.is_enum_value(v2))), do: struct.compare(v1, v2), else: struct.compare_args(v1, v2)
  end

end
