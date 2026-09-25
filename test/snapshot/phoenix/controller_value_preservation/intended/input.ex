defmodule Input do
  def accepted(arg0) do
    {:accepted, arg0}
  end
  def denied() do
    {:denied}
  end
  def __haxe_enum_constructs__() do
    ["Accepted", "Denied"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :accepted -> 0
        1 -> 1
        :denied -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Input"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Accepted"
        :accepted -> "Accepted"
        1 -> "Denied"
        :denied -> "Denied"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Input"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Accepted" when length(values) == 1 -> List.to_tuple([:accepted | values])
      "Accepted" -> raise "Enum constructor Accepted expects 1 params for Input"
      "Denied" when values == [] -> List.to_tuple([:denied | values])
      "Denied" -> raise "Enum constructor Denied expects 0 params for Input"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Input"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:accepted | values])
      0 -> raise "Enum constructor Accepted expects 1 params for Input"
      1 when values == [] -> List.to_tuple([:denied | values])
      1 -> raise "Enum constructor Denied expects 0 params for Input"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Input"
    end
  end
  def __haxe_enum_all__() do
    [{:denied}]
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
