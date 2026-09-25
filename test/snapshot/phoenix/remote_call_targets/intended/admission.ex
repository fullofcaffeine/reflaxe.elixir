defmodule Admission do
  def denied() do
    {0}
  end
  def granted(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Denied", "Granted"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :denied -> 0
        1 -> 1
        :granted -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Admission"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Denied"
        :denied -> "Denied"
        1 -> "Granted"
        :granted -> "Granted"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Admission"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Denied" when values == [] -> List.to_tuple([:denied | values])
      "Denied" -> raise "Enum constructor Denied expects 0 params for Admission"
      "Granted" when length(values) == 1 -> List.to_tuple([:granted | values])
      "Granted" -> raise "Enum constructor Granted expects 1 params for Admission"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Admission"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:denied | values])
      0 -> raise "Enum constructor Denied expects 0 params for Admission"
      1 when length(values) == 1 -> List.to_tuple([:granted | values])
      1 -> raise "Enum constructor Granted expects 1 params for Admission"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Admission"
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
