defmodule MessageType do
  def custom(arg0) do
    {0, arg0}
  end
  def default(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Custom", "Default"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :custom -> 0
        1 -> 1
        :default -> 1
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
        0 -> "Custom"
        :custom -> "Custom"
        1 -> "Default"
        :default -> "Default"
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
      "Custom" when length(values) == 1 -> List.to_tuple([:custom | values])
      "Custom" -> raise "Enum constructor Custom expects 1 params for MessageType"
      "Default" when length(values) == 1 -> List.to_tuple([:default | values])
      "Default" -> raise "Enum constructor Default expects 1 params for MessageType"
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
      0 when length(values) == 1 -> List.to_tuple([:custom | values])
      0 -> raise "Enum constructor Custom expects 1 params for MessageType"
      1 when length(values) == 1 -> List.to_tuple([:default | values])
      1 -> raise "Enum constructor Default expects 1 params for MessageType"
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
