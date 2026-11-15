defmodule Outer do
  def wrap(arg0) do
    {0, arg0}
  end
  def both(arg0, arg1) do
    {1, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["Wrap", "Both"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :wrap -> 0
        1 -> 1
        :both -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Outer"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Wrap"
        :wrap -> "Wrap"
        1 -> "Both"
        :both -> "Both"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Outer"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Wrap" when length(values) == 1 -> List.to_tuple([:wrap | values])
      "Wrap" -> raise "Enum constructor Wrap expects 1 params for Outer"
      "Both" when length(values) == 2 -> List.to_tuple([:both | values])
      "Both" -> raise "Enum constructor Both expects 2 params for Outer"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Outer"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:wrap | values])
      0 -> raise "Enum constructor Wrap expects 1 params for Outer"
      1 when length(values) == 2 -> List.to_tuple([:both | values])
      1 -> raise "Enum constructor Both expects 2 params for Outer"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Outer"
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
