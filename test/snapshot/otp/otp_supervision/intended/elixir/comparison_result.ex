defmodule Elixir.ComparisonResult do
  def less_than() do
    {0}
  end
  def equal() do
    {1}
  end
  def greater_than() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["LessThan", "Equal", "GreaterThan"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :less_than -> 0
        1 -> 1
        :equal -> 1
        2 -> 2
        :greater_than -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.ComparisonResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "LessThan"
        :less_than -> "LessThan"
        1 -> "Equal"
        :equal -> "Equal"
        2 -> "GreaterThan"
        :greater_than -> "GreaterThan"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.ComparisonResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "LessThan" when values == [] -> List.to_tuple([:less_than | values])
      "LessThan" -> raise "Enum constructor LessThan expects 0 params for Elixir.ComparisonResult"
      "Equal" when values == [] -> List.to_tuple([:equal | values])
      "Equal" -> raise "Enum constructor Equal expects 0 params for Elixir.ComparisonResult"
      "GreaterThan" when values == [] -> List.to_tuple([:greater_than | values])
      "GreaterThan" -> raise "Enum constructor GreaterThan expects 0 params for Elixir.ComparisonResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.ComparisonResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:less_than | values])
      0 -> raise "Enum constructor LessThan expects 0 params for Elixir.ComparisonResult"
      1 when values == [] -> List.to_tuple([:equal | values])
      1 -> raise "Enum constructor Equal expects 0 params for Elixir.ComparisonResult"
      2 when values == [] -> List.to_tuple([:greater_than | values])
      2 -> raise "Enum constructor GreaterThan expects 0 params for Elixir.ComparisonResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.ComparisonResult"
    end
  end
  def __haxe_enum_all__() do
    [{:less_than}, {:equal}, {:greater_than}]
  end
  def __haxe_enum_eq__(left, right) do
    left_name = __haxe_enum_constructor__(left)
    right_name = __haxe_enum_constructor__(right)
    left_params = case left do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    right_params = case right do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    left_name == right_name and left_params == right_params
  end
end
