defmodule Option do
  def none() do
    {0}
  end
  def some(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["None", "Some"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :none -> 0
        1 -> 1
        :some -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Option"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "None"
        :none -> "None"
        1 -> "Some"
        :some -> "Some"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Option"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "None" when values == [] -> List.to_tuple([:none | values])
      "None" -> raise "Enum constructor None expects 0 params for Option"
      "Some" when length(values) == 1 -> List.to_tuple([:some | values])
      "Some" -> raise "Enum constructor Some expects 1 params for Option"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Option"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:none | values])
      0 -> raise "Enum constructor None expects 0 params for Option"
      1 when length(values) == 1 -> List.to_tuple([:some | values])
      1 -> raise "Enum constructor Some expects 1 params for Option"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Option"
    end
  end
  def __haxe_enum_all__() do
    [{:none}]
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
