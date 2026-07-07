defmodule BuilderItem do
  def add_item(arg0, arg1) do
    {0, arg0, arg1}
  end
  def remove_item(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["AddItem", "RemoveItem"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :add_item -> 0
        1 -> 1
        :remove_item -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for BuilderItem"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "AddItem"
        :add_item -> "AddItem"
        1 -> "RemoveItem"
        :remove_item -> "RemoveItem"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for BuilderItem"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "AddItem" when length(values) == 2 -> List.to_tuple([:add_item | values])
      "AddItem" -> raise "Enum constructor AddItem expects 2 params for BuilderItem"
      "RemoveItem" when length(values) == 1 -> List.to_tuple([:remove_item | values])
      "RemoveItem" -> raise "Enum constructor RemoveItem expects 1 params for BuilderItem"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for BuilderItem"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:add_item | values])
      0 -> raise "Enum constructor AddItem expects 2 params for BuilderItem"
      1 when length(values) == 1 -> List.to_tuple([:remove_item | values])
      1 -> raise "Enum constructor RemoveItem expects 1 params for BuilderItem"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for BuilderItem"
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
