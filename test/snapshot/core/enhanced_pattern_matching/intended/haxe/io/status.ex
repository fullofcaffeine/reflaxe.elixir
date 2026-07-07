defmodule Status do
  def idle() do
    {0}
  end
  def working(arg0) do
    {1, arg0}
  end
  def completed(arg0, arg1) do
    {2, arg0, arg1}
  end
  def failed(arg0, arg1) do
    {3, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["Idle", "Working", "Completed", "Failed"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :idle -> 0
        1 -> 1
        :working -> 1
        2 -> 2
        :completed -> 2
        3 -> 3
        :failed -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Status"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Idle"
        :idle -> "Idle"
        1 -> "Working"
        :working -> "Working"
        2 -> "Completed"
        :completed -> "Completed"
        3 -> "Failed"
        :failed -> "Failed"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Status"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Idle" when values == [] -> List.to_tuple([:idle | values])
      "Idle" -> raise "Enum constructor Idle expects 0 params for Status"
      "Working" when length(values) == 1 -> List.to_tuple([:working | values])
      "Working" -> raise "Enum constructor Working expects 1 params for Status"
      "Completed" when length(values) == 2 -> List.to_tuple([:completed | values])
      "Completed" -> raise "Enum constructor Completed expects 2 params for Status"
      "Failed" when length(values) == 2 -> List.to_tuple([:failed | values])
      "Failed" -> raise "Enum constructor Failed expects 2 params for Status"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Status"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:idle | values])
      0 -> raise "Enum constructor Idle expects 0 params for Status"
      1 when length(values) == 1 -> List.to_tuple([:working | values])
      1 -> raise "Enum constructor Working expects 1 params for Status"
      2 when length(values) == 2 -> List.to_tuple([:completed | values])
      2 -> raise "Enum constructor Completed expects 2 params for Status"
      3 when length(values) == 2 -> List.to_tuple([:failed | values])
      3 -> raise "Enum constructor Failed expects 2 params for Status"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Status"
    end
  end
  def __haxe_enum_all__() do
    [{:idle}]
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
