defmodule EnumValueMap do
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
    (
  d = Type.enumIndex(k1) - Type.enumIndex(k2)
  if (d != 0), do: d, else: nil
  p1 = Type.enumParameters(k1)
  p2 = Type.enumParameters(k2)
  if (p1.length == 0 && p2.length == 0), do: 0, else: nil
  self().compareArgs(p1, p2)
)
  end

  @doc "Function compare_args"
  @spec compare_args(Array.t(), Array.t()) :: integer()
  def compare_args(arg0, arg1) do
    (
  ld = a1.length - a2.length
  if (ld != 0), do: ld, else: nil
  (
  _g = 0
  _g1 = a1.length
  while (_g < _g1) do
  (
  i = _g + 1
  d = self().compareArg(Enum.at(a1, i), Enum.at(a2, i))
  if (d != 0), do: d, else: nil
)
end
)
  0
)
  end

  @doc "Function compare_arg"
  @spec compare_arg(term(), term()) :: integer()
  def compare_arg(arg0, arg1) do
    (
  temp_result = nil
  if (Reflect.isEnumValue(v1) && Reflect.isEnumValue(v2)), do: temp_result = self().compare(v1, v2), else: if (Std.isOfType(v1, Array) && Std.isOfType(v2, Array)), do: temp_result = self().compareArgs(v1, v2), else: temp_result = Reflect.compare(v1, v2)
  temp_result
)
  end

end
