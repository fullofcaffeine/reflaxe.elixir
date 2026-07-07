defmodule MessageType do
  def created(arg0) do
    {0, arg0}
  end
  def updated(arg0, arg1) do
    {1, arg0, arg1}
  end
  def deleted(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Created", "Updated", "Deleted"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :created -> 0
        1 -> 1
        :updated -> 1
        2 -> 2
        :deleted -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for MessageType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Created"
        :created -> "Created"
        1 -> "Updated"
        :updated -> "Updated"
        2 -> "Deleted"
        :deleted -> "Deleted"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for MessageType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Created" when length(values) == 1 -> List.to_tuple([:created | values])
      "Created" -> raise "Enum constructor Created expects 1 params for MessageType"
      "Updated" when length(values) == 2 -> List.to_tuple([:updated | values])
      "Updated" -> raise "Enum constructor Updated expects 2 params for MessageType"
      "Deleted" when length(values) == 1 -> List.to_tuple([:deleted | values])
      "Deleted" -> raise "Enum constructor Deleted expects 1 params for MessageType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for MessageType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:created | values])
      0 -> raise "Enum constructor Created expects 1 params for MessageType"
      1 when length(values) == 2 -> List.to_tuple([:updated | values])
      1 -> raise "Enum constructor Updated expects 2 params for MessageType"
      2 when length(values) == 1 -> List.to_tuple([:deleted | values])
      2 -> raise "Enum constructor Deleted expects 1 params for MessageType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for MessageType"
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
