defmodule BulkAction do
  def complete_all() do
    {0}
  end
  def delete_completed() do
    {1}
  end
  def set_priority(arg0) do
    {2, arg0}
  end
  def add_tag(arg0) do
    {3, arg0}
  end
  def remove_tag(arg0) do
    {4, arg0}
  end
  def __haxe_enum_constructs__() do
    ["CompleteAll", "DeleteCompleted", "SetPriority", "AddTag", "RemoveTag"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :complete_all -> 0
        1 -> 1
        :delete_completed -> 1
        2 -> 2
        :set_priority -> 2
        3 -> 3
        :add_tag -> 3
        4 -> 4
        :remove_tag -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for BulkAction"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "CompleteAll"
        :complete_all -> "CompleteAll"
        1 -> "DeleteCompleted"
        :delete_completed -> "DeleteCompleted"
        2 -> "SetPriority"
        :set_priority -> "SetPriority"
        3 -> "AddTag"
        :add_tag -> "AddTag"
        4 -> "RemoveTag"
        :remove_tag -> "RemoveTag"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for BulkAction"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "CompleteAll" when values == [] -> List.to_tuple([:complete_all | values])
      "CompleteAll" -> raise "Enum constructor CompleteAll expects 0 params for BulkAction"
      "DeleteCompleted" when values == [] -> List.to_tuple([:delete_completed | values])
      "DeleteCompleted" -> raise "Enum constructor DeleteCompleted expects 0 params for BulkAction"
      "SetPriority" when length(values) == 1 -> List.to_tuple([:set_priority | values])
      "SetPriority" -> raise "Enum constructor SetPriority expects 1 params for BulkAction"
      "AddTag" when length(values) == 1 -> List.to_tuple([:add_tag | values])
      "AddTag" -> raise "Enum constructor AddTag expects 1 params for BulkAction"
      "RemoveTag" when length(values) == 1 -> List.to_tuple([:remove_tag | values])
      "RemoveTag" -> raise "Enum constructor RemoveTag expects 1 params for BulkAction"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for BulkAction"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:complete_all | values])
      0 -> raise "Enum constructor CompleteAll expects 0 params for BulkAction"
      1 when values == [] -> List.to_tuple([:delete_completed | values])
      1 -> raise "Enum constructor DeleteCompleted expects 0 params for BulkAction"
      2 when length(values) == 1 -> List.to_tuple([:set_priority | values])
      2 -> raise "Enum constructor SetPriority expects 1 params for BulkAction"
      3 when length(values) == 1 -> List.to_tuple([:add_tag | values])
      3 -> raise "Enum constructor AddTag expects 1 params for BulkAction"
      4 when length(values) == 1 -> List.to_tuple([:remove_tag | values])
      4 -> raise "Enum constructor RemoveTag expects 1 params for BulkAction"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for BulkAction"
    end
  end
  def __haxe_enum_all__() do
    [{:complete_all}, {:delete_completed}]
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
