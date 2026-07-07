defmodule Status do
  def active(arg0) do
    {0, arg0}
  end
  def inactive() do
    {1}
  end
  def suspended(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Active", "Inactive", "Suspended"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :active -> 0
        1 -> 1
        :inactive -> 1
        2 -> 2
        :suspended -> 2
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
        0 -> "Active"
        :active -> "Active"
        1 -> "Inactive"
        :inactive -> "Inactive"
        2 -> "Suspended"
        :suspended -> "Suspended"
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
      "Active" when length(values) == 1 -> List.to_tuple([:active | values])
      "Active" -> raise "Enum constructor Active expects 1 params for Status"
      "Inactive" when values == [] -> List.to_tuple([:inactive | values])
      "Inactive" -> raise "Enum constructor Inactive expects 0 params for Status"
      "Suspended" when length(values) == 1 -> List.to_tuple([:suspended | values])
      "Suspended" -> raise "Enum constructor Suspended expects 1 params for Status"
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
      0 when length(values) == 1 -> List.to_tuple([:active | values])
      0 -> raise "Enum constructor Active expects 1 params for Status"
      1 when values == [] -> List.to_tuple([:inactive | values])
      1 -> raise "Enum constructor Inactive expects 0 params for Status"
      2 when length(values) == 1 -> List.to_tuple([:suspended | values])
      2 -> raise "Enum constructor Suspended expects 1 params for Status"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Status"
    end
  end
  def __haxe_enum_all__() do
    [{:inactive}]
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
