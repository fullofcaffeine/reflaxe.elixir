defmodule Container do
  def box(arg0) do
    {0, arg0}
  end
  def list(arg0) do
    {1, arg0}
  end
  def empty() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["Box", "List", "Empty"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :box -> 0
        1 -> 1
        :list -> 1
        2 -> 2
        :empty -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Container"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Box"
        :box -> "Box"
        1 -> "List"
        :list -> "List"
        2 -> "Empty"
        :empty -> "Empty"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Container"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Box" when length(values) == 1 -> List.to_tuple([:box | values])
      "Box" -> raise "Enum constructor Box expects 1 params for Container"
      "List" when length(values) == 1 -> List.to_tuple([:list | values])
      "List" -> raise "Enum constructor List expects 1 params for Container"
      "Empty" when values == [] -> List.to_tuple([:empty | values])
      "Empty" -> raise "Enum constructor Empty expects 0 params for Container"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Container"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:box | values])
      0 -> raise "Enum constructor Box expects 1 params for Container"
      1 when length(values) == 1 -> List.to_tuple([:list | values])
      1 -> raise "Enum constructor List expects 1 params for Container"
      2 when values == [] -> List.to_tuple([:empty | values])
      2 -> raise "Enum constructor Empty expects 0 params for Container"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Container"
    end
  end
  def __haxe_enum_all__() do
    [{:empty}]
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
