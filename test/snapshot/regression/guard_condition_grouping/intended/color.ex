defmodule Color do
  def rgb(arg0, arg1, arg2) do
    {0, arg0, arg1, arg2}
  end
  def hsl(arg0, arg1, arg2) do
    {1, arg0, arg1, arg2}
  end
  def named(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["RGB", "HSL", "Named"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :rgb -> 0
        1 -> 1
        :hsl -> 1
        2 -> 2
        :named -> 2
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
        0 -> "RGB"
        :rgb -> "RGB"
        1 -> "HSL"
        :hsl -> "HSL"
        2 -> "Named"
        :named -> "Named"
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
      "RGB" when length(values) == 3 -> List.to_tuple([:rgb | values])
      "RGB" -> raise "Enum constructor RGB expects 3 params for Color"
      "HSL" when length(values) == 3 -> List.to_tuple([:hsl | values])
      "HSL" -> raise "Enum constructor HSL expects 3 params for Color"
      "Named" when length(values) == 1 -> List.to_tuple([:named | values])
      "Named" -> raise "Enum constructor Named expects 1 params for Color"
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
      0 when length(values) == 3 -> List.to_tuple([:rgb | values])
      0 -> raise "Enum constructor RGB expects 3 params for Color"
      1 when length(values) == 3 -> List.to_tuple([:hsl | values])
      1 -> raise "Enum constructor HSL expects 3 params for Color"
      2 when length(values) == 1 -> List.to_tuple([:named | values])
      2 -> raise "Enum constructor Named expects 1 params for Color"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Color"
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
