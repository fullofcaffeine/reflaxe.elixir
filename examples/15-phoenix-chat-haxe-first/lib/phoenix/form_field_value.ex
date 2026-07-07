defmodule Phoenix.FormFieldValue do
  def string_value(arg0) do
    {:string_value, arg0}
  end
  def int_value(arg0) do
    {:int_value, arg0}
  end
  def float_value(arg0) do
    {:float_value, arg0}
  end
  def bool_value(arg0) do
    {:bool_value, arg0}
  end
  def array_value(arg0) do
    {:array_value, arg0}
  end
  def __haxe_enum_constructs__() do
    ["StringValue", "IntValue", "FloatValue", "BoolValue", "ArrayValue"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :string_value -> 0
        1 -> 1
        :int_value -> 1
        2 -> 2
        :float_value -> 2
        3 -> 3
        :bool_value -> 3
        4 -> 4
        :array_value -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.FormFieldValue"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "StringValue"
        :string_value -> "StringValue"
        1 -> "IntValue"
        :int_value -> "IntValue"
        2 -> "FloatValue"
        :float_value -> "FloatValue"
        3 -> "BoolValue"
        :bool_value -> "BoolValue"
        4 -> "ArrayValue"
        :array_value -> "ArrayValue"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.FormFieldValue"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "StringValue" when length(values) == 1 -> List.to_tuple([:string_value | values])
      "StringValue" -> raise "Enum constructor StringValue expects 1 params for Phoenix.FormFieldValue"
      "IntValue" when length(values) == 1 -> List.to_tuple([:int_value | values])
      "IntValue" -> raise "Enum constructor IntValue expects 1 params for Phoenix.FormFieldValue"
      "FloatValue" when length(values) == 1 -> List.to_tuple([:float_value | values])
      "FloatValue" -> raise "Enum constructor FloatValue expects 1 params for Phoenix.FormFieldValue"
      "BoolValue" when length(values) == 1 -> List.to_tuple([:bool_value | values])
      "BoolValue" -> raise "Enum constructor BoolValue expects 1 params for Phoenix.FormFieldValue"
      "ArrayValue" when length(values) == 1 -> List.to_tuple([:array_value | values])
      "ArrayValue" -> raise "Enum constructor ArrayValue expects 1 params for Phoenix.FormFieldValue"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.FormFieldValue"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:string_value | values])
      0 -> raise "Enum constructor StringValue expects 1 params for Phoenix.FormFieldValue"
      1 when length(values) == 1 -> List.to_tuple([:int_value | values])
      1 -> raise "Enum constructor IntValue expects 1 params for Phoenix.FormFieldValue"
      2 when length(values) == 1 -> List.to_tuple([:float_value | values])
      2 -> raise "Enum constructor FloatValue expects 1 params for Phoenix.FormFieldValue"
      3 when length(values) == 1 -> List.to_tuple([:bool_value | values])
      3 -> raise "Enum constructor BoolValue expects 1 params for Phoenix.FormFieldValue"
      4 when length(values) == 1 -> List.to_tuple([:array_value | values])
      4 -> raise "Enum constructor ArrayValue expects 1 params for Phoenix.FormFieldValue"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.FormFieldValue"
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
