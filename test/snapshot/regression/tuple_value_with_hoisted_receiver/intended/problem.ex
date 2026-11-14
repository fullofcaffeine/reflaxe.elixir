defmodule Problem do
  def negative(arg0) do
    {0, arg0}
  end
  def missing(arg0, arg1) do
    {1, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["Negative", "Missing"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :negative -> 0
        1 -> 1
        :missing -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Problem"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Negative"
        :negative -> "Negative"
        1 -> "Missing"
        :missing -> "Missing"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Problem"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Negative" when length(values) == 1 -> List.to_tuple([:negative | values])
      "Negative" -> raise "Enum constructor Negative expects 1 params for Problem"
      "Missing" when length(values) == 2 -> List.to_tuple([:missing | values])
      "Missing" -> raise "Enum constructor Missing expects 2 params for Problem"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Problem"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:negative | values])
      0 -> raise "Enum constructor Negative expects 1 params for Problem"
      1 when length(values) == 2 -> List.to_tuple([:missing | values])
      1 -> raise "Enum constructor Missing expects 2 params for Problem"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Problem"
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
