defmodule Event do
  def click(arg0, arg1) do
    {0, arg0, arg1}
  end
  def hover(arg0, arg1) do
    {1, arg0, arg1}
  end
  def key_press(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Click", "Hover", "KeyPress"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :click -> 0
        1 -> 1
        :hover -> 1
        2 -> 2
        :key_press -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Event"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Click"
        :click -> "Click"
        1 -> "Hover"
        :hover -> "Hover"
        2 -> "KeyPress"
        :key_press -> "KeyPress"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Event"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Click" when length(values) == 2 -> List.to_tuple([:click | values])
      "Click" -> raise "Enum constructor Click expects 2 params for Event"
      "Hover" when length(values) == 2 -> List.to_tuple([:hover | values])
      "Hover" -> raise "Enum constructor Hover expects 2 params for Event"
      "KeyPress" when length(values) == 1 -> List.to_tuple([:key_press | values])
      "KeyPress" -> raise "Enum constructor KeyPress expects 1 params for Event"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Event"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:click | values])
      0 -> raise "Enum constructor Click expects 2 params for Event"
      1 when length(values) == 2 -> List.to_tuple([:hover | values])
      1 -> raise "Enum constructor Hover expects 2 params for Event"
      2 when length(values) == 1 -> List.to_tuple([:key_press | values])
      2 -> raise "Enum constructor KeyPress expects 1 params for Event"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Event"
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
