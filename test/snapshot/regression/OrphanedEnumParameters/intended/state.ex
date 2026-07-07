defmodule State do
  def loading(arg0) do
    {0, arg0}
  end
  def processing(arg0) do
    {1, arg0}
  end
  def complete(arg0) do
    {2, arg0}
  end
  def error(arg0) do
    {3, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Loading", "Processing", "Complete", "Error"]
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
        :processing -> 1
        2 -> 2
        :complete -> 2
        3 -> 3
        :error -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for State"
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
        1 -> "Processing"
        :processing -> "Processing"
        2 -> "Complete"
        :complete -> "Complete"
        3 -> "Error"
        :error -> "Error"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for State"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Loading" when length(values) == 1 -> List.to_tuple([:loading | values])
      "Loading" -> raise "Enum constructor Loading expects 1 params for State"
      "Processing" when length(values) == 1 -> List.to_tuple([:processing | values])
      "Processing" -> raise "Enum constructor Processing expects 1 params for State"
      "Complete" when length(values) == 1 -> List.to_tuple([:complete | values])
      "Complete" -> raise "Enum constructor Complete expects 1 params for State"
      "Error" when length(values) == 1 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 1 params for State"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for State"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:loading | values])
      0 -> raise "Enum constructor Loading expects 1 params for State"
      1 when length(values) == 1 -> List.to_tuple([:processing | values])
      1 -> raise "Enum constructor Processing expects 1 params for State"
      2 when length(values) == 1 -> List.to_tuple([:complete | values])
      2 -> raise "Enum constructor Complete expects 1 params for State"
      3 when length(values) == 1 -> List.to_tuple([:error | values])
      3 -> raise "Enum constructor Error expects 1 params for State"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for State"
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
