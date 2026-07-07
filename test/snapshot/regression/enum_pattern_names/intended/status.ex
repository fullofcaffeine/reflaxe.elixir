defmodule Status do
  def loading() do
    {0}
  end
  def success(arg0) do
    {1, arg0}
  end
  def failure(arg0, arg1) do
    {2, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["Loading", "Success", "Failure"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :loading -> 0
        1 -> 1
        :success -> 1
        2 -> 2
        :failure -> 2
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
        0 -> "Loading"
        :loading -> "Loading"
        1 -> "Success"
        :success -> "Success"
        2 -> "Failure"
        :failure -> "Failure"
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
      "Loading" when values == [] -> List.to_tuple([:loading | values])
      "Loading" -> raise "Enum constructor Loading expects 0 params for Status"
      "Success" when length(values) == 1 -> List.to_tuple([:success | values])
      "Success" -> raise "Enum constructor Success expects 1 params for Status"
      "Failure" when length(values) == 2 -> List.to_tuple([:failure | values])
      "Failure" -> raise "Enum constructor Failure expects 2 params for Status"
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
      0 when values == [] -> List.to_tuple([:loading | values])
      0 -> raise "Enum constructor Loading expects 0 params for Status"
      1 when length(values) == 1 -> List.to_tuple([:success | values])
      1 -> raise "Enum constructor Success expects 1 params for Status"
      2 when length(values) == 2 -> List.to_tuple([:failure | values])
      2 -> raise "Enum constructor Failure expects 2 params for Status"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Status"
    end
  end
  def __haxe_enum_all__() do
    [{:loading}]
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
