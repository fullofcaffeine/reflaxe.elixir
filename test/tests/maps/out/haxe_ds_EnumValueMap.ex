defmodule EnumValueMap do
  @moduledoc """
  EnumValueMap module generated from Haxe
  
  
	EnumValueMap allows mapping of enum value keys to arbitrary values.

	Keys are compared by value and recursively over their parameters. If any
	parameter is not an enum value, `Reflect.compare` is used to compare them.

  """

  # Instance functions
  @doc "Function compare"
  @spec compare(TAbstract(EnumValue,[]).t(), TAbstract(EnumValue,[]).t()) :: TAbstract(Int,[]).t()
  def compare(arg0, arg1) do
    (
  d = Type.enum_index(k1) - Type.enum_index(k2)
  if (d != 0), do: d, else: nil
  p1 = Type.enum_parameters(k1)
  p2 = Type.enum_parameters(k2)
  if (p1.length == 0 && p2.length == 0), do: 0, else: nil
  self().compare_args(p1, p2)
)
  end

  @doc "Function compare_args"
  @spec compare_args(TInst(Array,[TDynamic(null)]).t(), TInst(Array,[TDynamic(null)]).t()) :: TAbstract(Int,[]).t()
  def compare_args(arg0, arg1) do
    (
  ld = a1.length - a2.length
  if (ld != 0), do: ld, else: nil
  (
  _g = 0
  _g1 = a1.length
  # TODO: Implement expression type: TWhile
)
  0
)
  end

  @doc "Function compare_arg"
  @spec compare_arg(TDynamic(null).t(), TDynamic(null).t()) :: TAbstract(Int,[]).t()
  def compare_arg(arg0, arg1) do
    (
  temp_result = nil
  if (Reflect.is_enum_value(v1) && Reflect.is_enum_value(v2)), do: temp_result = self().compare(v1, v2), else: if (Std.is_of_type(v1, # TODO: Implement expression type: TTypeExpr) && Std.is_of_type(v2, # TODO: Implement expression type: TTypeExpr)), do: temp_result = self().compare_args(v1, v2), else: temp_result = Reflect.compare(v1, v2)
  temp_result
)
  end

end
