defmodule DataResult do
  def data(arg0, arg1, arg2, arg3) do
    {0, arg0, arg1, arg2, arg3}
  end
  def no_data() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["Data", "NoData"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :data -> 0
        1 -> 1
        :no_data -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for DataResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Data"
        :data -> "Data"
        1 -> "NoData"
        :no_data -> "NoData"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for DataResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Data" when length(values) == 4 -> List.to_tuple([:data | values])
      "Data" -> raise "Enum constructor Data expects 4 params for DataResult"
      "NoData" when values == [] -> List.to_tuple([:no_data | values])
      "NoData" -> raise "Enum constructor NoData expects 0 params for DataResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for DataResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 4 -> List.to_tuple([:data | values])
      0 -> raise "Enum constructor Data expects 4 params for DataResult"
      1 when values == [] -> List.to_tuple([:no_data | values])
      1 -> raise "Enum constructor NoData expects 0 params for DataResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for DataResult"
    end
  end
  def __haxe_enum_all__() do
    [{:no_data}]
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
