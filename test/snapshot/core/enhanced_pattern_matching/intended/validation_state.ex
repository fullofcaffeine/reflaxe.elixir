defmodule ValidationState do
  def valid() do
    {0}
  end
  def invalid(arg0) do
    {1, arg0}
  end
  def pending(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Valid", "Invalid", "Pending"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :valid -> 0
        1 -> 1
        :invalid -> 1
        2 -> 2
        :pending -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for ValidationState"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Valid"
        :valid -> "Valid"
        1 -> "Invalid"
        :invalid -> "Invalid"
        2 -> "Pending"
        :pending -> "Pending"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for ValidationState"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Valid" when values == [] -> List.to_tuple([:valid | values])
      "Valid" -> raise "Enum constructor Valid expects 0 params for ValidationState"
      "Invalid" when length(values) == 1 -> List.to_tuple([:invalid | values])
      "Invalid" -> raise "Enum constructor Invalid expects 1 params for ValidationState"
      "Pending" when length(values) == 1 -> List.to_tuple([:pending | values])
      "Pending" -> raise "Enum constructor Pending expects 1 params for ValidationState"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for ValidationState"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:valid | values])
      0 -> raise "Enum constructor Valid expects 0 params for ValidationState"
      1 when length(values) == 1 -> List.to_tuple([:invalid | values])
      1 -> raise "Enum constructor Invalid expects 1 params for ValidationState"
      2 when length(values) == 1 -> List.to_tuple([:pending | values])
      2 -> raise "Enum constructor Pending expects 1 params for ValidationState"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for ValidationState"
    end
  end
  def __haxe_enum_all__() do
    [{:valid}]
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
