defmodule Color do
  def red() do
    {0}
  end
  def green() do
    {1}
  end
  def blue() do
    {2}
  end
  def rgb(arg0, arg1, arg2) do
    {3, arg0, arg1, arg2}
  end
  def __haxe_enum_constructs__() do
    ["Red", "Green", "Blue", "RGB"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :red -> 0
        1 -> 1
        :green -> 1
        2 -> 2
        :blue -> 2
        3 -> 3
        :rgb -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Color"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Red"
        :red -> "Red"
        1 -> "Green"
        :green -> "Green"
        2 -> "Blue"
        :blue -> "Blue"
        3 -> "RGB"
        :rgb -> "RGB"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Color"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Red" when values == [] -> List.to_tuple([:red | values])
      "Red" -> raise "Enum constructor Red expects 0 params for Color"
      "Green" when values == [] -> List.to_tuple([:green | values])
      "Green" -> raise "Enum constructor Green expects 0 params for Color"
      "Blue" when values == [] -> List.to_tuple([:blue | values])
      "Blue" -> raise "Enum constructor Blue expects 0 params for Color"
      "RGB" when length(values) == 3 -> List.to_tuple([:rgb | values])
      "RGB" -> raise "Enum constructor RGB expects 3 params for Color"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Color"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:red | values])
      0 -> raise "Enum constructor Red expects 0 params for Color"
      1 when values == [] -> List.to_tuple([:green | values])
      1 -> raise "Enum constructor Green expects 0 params for Color"
      2 when values == [] -> List.to_tuple([:blue | values])
      2 -> raise "Enum constructor Blue expects 0 params for Color"
      3 when length(values) == 3 -> List.to_tuple([:rgb | values])
      3 -> raise "Enum constructor RGB expects 3 params for Color"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Color"
    end
  end
  def __haxe_enum_all__() do
    [{:red}, {:green}, {:blue}]
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
