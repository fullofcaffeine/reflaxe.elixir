defmodule Wire do
  def number_value(arg0) do
    {0, arg0}
  end
  def null_value() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["NumberValue", "NullValue"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :number_value -> 0
        1 -> 1
        :null_value -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Wire"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "NumberValue"
        :number_value -> "NumberValue"
        1 -> "NullValue"
        :null_value -> "NullValue"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Wire"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "NumberValue" when length(values) == 1 -> List.to_tuple([:number_value | values])
      "NumberValue" -> raise "Enum constructor NumberValue expects 1 params for Wire"
      "NullValue" when values == [] -> List.to_tuple([:null_value | values])
      "NullValue" -> raise "Enum constructor NullValue expects 0 params for Wire"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Wire"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:number_value | values])
      0 -> raise "Enum constructor NumberValue expects 1 params for Wire"
      1 when values == [] -> List.to_tuple([:null_value | values])
      1 -> raise "Enum constructor NullValue expects 0 params for Wire"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Wire"
    end
  end
  def __haxe_enum_all__() do
    [{:null_value}]
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
