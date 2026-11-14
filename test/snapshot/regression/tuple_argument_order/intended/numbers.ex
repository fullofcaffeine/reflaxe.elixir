defmodule Numbers do
  def pair(arg0, arg1) do
    {0, arg0, arg1}
  end
  def triple(arg0, arg1, arg2) do
    {1, arg0, arg1, arg2}
  end
  def __haxe_enum_constructs__() do
    ["Pair", "Triple"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :pair -> 0
        1 -> 1
        :triple -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Numbers"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Pair"
        :pair -> "Pair"
        1 -> "Triple"
        :triple -> "Triple"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Numbers"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Pair" when length(values) == 2 -> List.to_tuple([:pair | values])
      "Pair" -> raise "Enum constructor Pair expects 2 params for Numbers"
      "Triple" when length(values) == 3 -> List.to_tuple([:triple | values])
      "Triple" -> raise "Enum constructor Triple expects 3 params for Numbers"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Numbers"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:pair | values])
      0 -> raise "Enum constructor Pair expects 2 params for Numbers"
      1 when length(values) == 3 -> List.to_tuple([:triple | values])
      1 -> raise "Enum constructor Triple expects 3 params for Numbers"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Numbers"
    end
  end
  def __haxe_enum_all__() do
    []
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
