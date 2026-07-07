defmodule Message do
  def bulk_update(arg0) do
    {0, arg0}
  end
  def system_alert(arg0, arg1) do
    {1, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["BulkUpdate", "SystemAlert"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :bulk_update -> 0
        1 -> 1
        :system_alert -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Message"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "BulkUpdate"
        :bulk_update -> "BulkUpdate"
        1 -> "SystemAlert"
        :system_alert -> "SystemAlert"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Message"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "BulkUpdate" when length(values) == 1 -> List.to_tuple([:bulk_update | values])
      "BulkUpdate" -> raise "Enum constructor BulkUpdate expects 1 params for Message"
      "SystemAlert" when length(values) == 2 -> List.to_tuple([:system_alert | values])
      "SystemAlert" -> raise "Enum constructor SystemAlert expects 2 params for Message"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Message"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:bulk_update | values])
      0 -> raise "Enum constructor BulkUpdate expects 1 params for Message"
      1 when length(values) == 2 -> List.to_tuple([:system_alert | values])
      1 -> raise "Enum constructor SystemAlert expects 2 params for Message"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Message"
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
