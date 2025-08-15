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
  def compare(k1, k2) do
    d = Type.enumIndex(k1) - Type.enumIndex(k2)
    if (d != 0), do: d, else: nil
    p1 = Type.enumParameters(k1)
    p2 = Type.enumParameters(k2)
    if (length(p1) == 0 && length(p2) == 0), do: 0, else: nil
    __MODULE__.compareArgs(p1, p2)
  end

  @doc "Function compare_args"
  @spec compare_args(Array.t(), Array.t()) :: integer()
  def compare_args(a1, a2) do
    ld = length(a1) - length(a2)
    if (ld != 0), do: ld, else: nil
    _g = 0
    _g = length(a1)
    (
      try do
        loop_fn = fn ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
    d = __MODULE__.compareArg(Enum.at(a1, i), Enum.at(a2, i))
    if (d != 0), do: d, else: nil
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    0
  end

  @doc "Function compare_arg"
  @spec compare_arg(term(), term()) :: integer()
  def compare_arg(v1, v2) do
    temp_result = nil
    if (Reflect.isEnumValue(v1) && Reflect.isEnumValue(v2)), do: temp_result = __MODULE__.compare(v1, v2), else: if (Std.isOfType(v1, Array) && Std.isOfType(v2, Array)), do: temp_result = __MODULE__.compareArgs(v1, v2), else: temp_result = Reflect.compare(v1, v2)
    temp_result
  end

end
