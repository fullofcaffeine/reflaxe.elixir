defmodule Result do
  def success(arg0, arg1) do
    {0, arg0, arg1}
  end
  def warning(arg0) do
    {1, arg0}
  end
  def error(arg0, arg1) do
    {2, arg0, arg1}
  end
  def pending() do
    {3}
  end
  def __haxe_enum_constructs__() do
    ["Success", "Warning", "Error", "Pending"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :success -> 0
        1 -> 1
        :warning -> 1
        2 -> 2
        :error -> 2
        3 -> 3
        :pending -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Result"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Success"
        :success -> "Success"
        1 -> "Warning"
        :warning -> "Warning"
        2 -> "Error"
        :error -> "Error"
        3 -> "Pending"
        :pending -> "Pending"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Result"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Success" when length(values) == 2 -> List.to_tuple([:success | values])
      "Success" -> raise "Enum constructor Success expects 2 params for Result"
      "Warning" when length(values) == 1 -> List.to_tuple([:warning | values])
      "Warning" -> raise "Enum constructor Warning expects 1 params for Result"
      "Error" when length(values) == 2 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 2 params for Result"
      "Pending" when values == [] -> List.to_tuple([:pending | values])
      "Pending" -> raise "Enum constructor Pending expects 0 params for Result"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Result"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:success | values])
      0 -> raise "Enum constructor Success expects 2 params for Result"
      1 when length(values) == 1 -> List.to_tuple([:warning | values])
      1 -> raise "Enum constructor Warning expects 1 params for Result"
      2 when length(values) == 2 -> List.to_tuple([:error | values])
      2 -> raise "Enum constructor Error expects 2 params for Result"
      3 when values == [] -> List.to_tuple([:pending | values])
      3 -> raise "Enum constructor Pending expects 0 params for Result"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Result"
    end
  end
  def __haxe_enum_all__() do
    [{:pending}]
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
