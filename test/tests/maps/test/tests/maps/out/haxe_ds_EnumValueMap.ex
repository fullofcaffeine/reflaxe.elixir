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
    # TODO: Implement function body
    nil
  end

  @doc "Function compare_args"
  @spec compare_args(TInst(Array,[TDynamic(null)]).t(), TInst(Array,[TDynamic(null)]).t()) :: TAbstract(Int,[]).t()
  def compare_args(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

  @doc "Function compare_arg"
  @spec compare_arg(TDynamic(null).t(), TDynamic(null).t()) :: TAbstract(Int,[]).t()
  def compare_arg(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

end
