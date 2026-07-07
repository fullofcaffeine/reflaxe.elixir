defmodule TestEnum do
  def option1(arg0) do
    {0, arg0}
  end
  def option2(arg0) do
    {1, arg0}
  end
  def option3() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["Option1", "Option2", "Option3"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :option1 -> 0
        1 -> 1
        :option2 -> 1
        2 -> 2
        :option3 -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TestEnum"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Option1"
        :option1 -> "Option1"
        1 -> "Option2"
        :option2 -> "Option2"
        2 -> "Option3"
        :option3 -> "Option3"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TestEnum"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Option1" when length(values) == 1 -> List.to_tuple([:option1 | values])
      "Option1" -> raise "Enum constructor Option1 expects 1 params for TestEnum"
      "Option2" when length(values) == 1 -> List.to_tuple([:option2 | values])
      "Option2" -> raise "Enum constructor Option2 expects 1 params for TestEnum"
      "Option3" when values == [] -> List.to_tuple([:option3 | values])
      "Option3" -> raise "Enum constructor Option3 expects 0 params for TestEnum"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for TestEnum"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:option1 | values])
      0 -> raise "Enum constructor Option1 expects 1 params for TestEnum"
      1 when length(values) == 1 -> List.to_tuple([:option2 | values])
      1 -> raise "Enum constructor Option2 expects 1 params for TestEnum"
      2 when values == [] -> List.to_tuple([:option3 | values])
      2 -> raise "Enum constructor Option3 expects 0 params for TestEnum"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for TestEnum"
    end
  end
  def __haxe_enum_all__() do
    [{:option3}]
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
