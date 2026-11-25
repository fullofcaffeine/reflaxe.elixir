defmodule ResourceHookEvent do
  def resource_selected(arg0) do
    {0, arg0}
  end
  def ping() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["ResourceSelected", "Ping"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :resource_selected -> 0
        1 -> 1
        :ping -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for ResourceHookEvent"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "ResourceSelected"
        :resource_selected -> "ResourceSelected"
        1 -> "Ping"
        :ping -> "Ping"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for ResourceHookEvent"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "ResourceSelected" when length(values) == 1 -> List.to_tuple([:resource_selected | values])
      "ResourceSelected" -> raise "Enum constructor ResourceSelected expects 1 params for ResourceHookEvent"
      "Ping" when values == [] -> List.to_tuple([:ping | values])
      "Ping" -> raise "Enum constructor Ping expects 0 params for ResourceHookEvent"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for ResourceHookEvent"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:resource_selected | values])
      0 -> raise "Enum constructor ResourceSelected expects 1 params for ResourceHookEvent"
      1 when values == [] -> List.to_tuple([:ping | values])
      1 -> raise "Enum constructor Ping expects 0 params for ResourceHookEvent"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for ResourceHookEvent"
    end
  end
  def __haxe_enum_all__() do
    [{:ping}]
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
