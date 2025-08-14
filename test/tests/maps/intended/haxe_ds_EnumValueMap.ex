defmodule EnumValueMap do
  use Bitwise
  @behaviour IMap

  @moduledoc """
  EnumValueMap module generated from Haxe
  
  
	EnumValueMap allows mapping of enum value keys to arbitrary values.

	Keys are compared by value and recursively over their parameters. If any
	parameter is not an enum value, `Reflect.compare` is used to compare them.

  """

  # Instance functions
  @doc "Function compare"
  @spec compare(EnumValue.t(), EnumValue.t()) :: integer()
  def compare(arg0, arg1) do
    d = Type.enumIndex(arg0) - Type.enumIndex(arg1)
if (d != 0), do: d, else: nil
p1 = Type.enumParameters(arg0)
p2 = Type.enumParameters(arg1)
if (length(p1) == 0 && length(p2) == 0), do: 0, else: nil
__MODULE__.compareArgs(p1, p2)
  end

  @doc "Function compare_args"
  @spec compare_args(Array.t(), Array.t()) :: integer()
  def compare_args(arg0, arg1) do
    ld = length(arg0) - length(arg1)
if (ld != 0), do: ld, else: nil
_g = 0
_g1 = length(arg0)
(fn loop_fn ->
  if (_g < _g1) do
    i = _g + 1
d = __MODULE__.compareArg(Enum.at(arg0, i), Enum.at(arg1, i))
if (d != 0), do: d, else: nil
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
0
  end

  @doc "Function compare_arg"
  @spec compare_arg(term(), term()) :: integer()
  def compare_arg(arg0, arg1) do
    temp_result = nil
if (Reflect.isEnumValue(arg0) && Reflect.isEnumValue(arg1)), do: temp_result = __MODULE__.compare(arg0, arg1), else: if (Std.isOfType(arg0, Array) && Std.isOfType(arg1, Array)), do: temp_result = __MODULE__.compareArgs(arg0, arg1), else: temp_result = Reflect.compare(arg0, arg1)
temp_result
  end

end
