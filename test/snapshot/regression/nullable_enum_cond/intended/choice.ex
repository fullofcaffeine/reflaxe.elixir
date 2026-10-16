defmodule Choice do
  def first(arg0) do
    {0, arg0}
  end
  def second(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["First", "Second"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :first -> 0
        1 -> 1
        :second -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Choice"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "First"
        :first -> "First"
        1 -> "Second"
        :second -> "Second"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Choice"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "First" when length(values) == 1 -> List.to_tuple([:first | values])
      "First" -> raise "Enum constructor First expects 1 params for Choice"
      "Second" when length(values) == 1 -> List.to_tuple([:second | values])
      "Second" -> raise "Enum constructor Second expects 1 params for Choice"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Choice"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:first | values])
      0 -> raise "Enum constructor First expects 1 params for Choice"
      1 when length(values) == 1 -> List.to_tuple([:second | values])
      1 -> raise "Enum constructor Second expects 1 params for Choice"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Choice"
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
