defmodule Ecto.JsonLibrary do
  def jason() do
    {0}
  end
  def poison() do
    {1}
  end
  def none() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["Jason", "Poison", "None"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :jason -> 0
        1 -> 1
        :poison -> 1
        2 -> 2
        :none -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.JsonLibrary"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Jason"
        :jason -> "Jason"
        1 -> "Poison"
        :poison -> "Poison"
        2 -> "None"
        :none -> "None"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Ecto.JsonLibrary"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Jason" when values == [] -> List.to_tuple([:jason | values])
      "Jason" -> raise "Enum constructor Jason expects 0 params for Ecto.JsonLibrary"
      "Poison" when values == [] -> List.to_tuple([:poison | values])
      "Poison" -> raise "Enum constructor Poison expects 0 params for Ecto.JsonLibrary"
      "None" when values == [] -> List.to_tuple([:none | values])
      "None" -> raise "Enum constructor None expects 0 params for Ecto.JsonLibrary"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Ecto.JsonLibrary"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:jason | values])
      0 -> raise "Enum constructor Jason expects 0 params for Ecto.JsonLibrary"
      1 when values == [] -> List.to_tuple([:poison | values])
      1 -> raise "Enum constructor Poison expects 0 params for Ecto.JsonLibrary"
      2 when values == [] -> List.to_tuple([:none | values])
      2 -> raise "Enum constructor None expects 0 params for Ecto.JsonLibrary"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Ecto.JsonLibrary"
    end
  end
  def __haxe_enum_all__() do
    [{:jason}, {:poison}, {:none}]
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
