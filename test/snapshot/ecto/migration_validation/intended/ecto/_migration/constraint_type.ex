defmodule Ecto.Migration.ConstraintType do
  def unique() do
    {0}
  end
  def check() do
    {1}
  end
  def exclusion() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["Unique", "Check", "Exclusion"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :unique -> 0
        1 -> 1
        :check -> 1
        2 -> 2
        :exclusion -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.Migration.ConstraintType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Unique"
        :unique -> "Unique"
        1 -> "Check"
        :check -> "Check"
        2 -> "Exclusion"
        :exclusion -> "Exclusion"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.Migration.ConstraintType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Unique" when values == [] -> List.to_tuple([:unique | values])
      "Unique" -> raise "Enum constructor Unique expects 0 params for Ecto.Migration.ConstraintType"
      "Check" when values == [] -> List.to_tuple([:check | values])
      "Check" -> raise "Enum constructor Check expects 0 params for Ecto.Migration.ConstraintType"
      "Exclusion" when values == [] -> List.to_tuple([:exclusion | values])
      "Exclusion" -> raise "Enum constructor Exclusion expects 0 params for Ecto.Migration.ConstraintType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.Migration.ConstraintType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:unique | values])
      0 -> raise "Enum constructor Unique expects 0 params for Ecto.Migration.ConstraintType"
      1 when values == [] -> List.to_tuple([:check | values])
      1 -> raise "Enum constructor Check expects 0 params for Ecto.Migration.ConstraintType"
      2 when values == [] -> List.to_tuple([:exclusion | values])
      2 -> raise "Enum constructor Exclusion expects 0 params for Ecto.Migration.ConstraintType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.Migration.ConstraintType"
    end
  end
  def __haxe_enum_all__() do
    [{:unique}, {:check}, {:exclusion}]
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
