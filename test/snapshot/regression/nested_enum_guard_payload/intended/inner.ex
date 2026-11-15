defmodule Inner do
  def stale(arg0, arg1) do
    {0, arg0, arg1}
  end
  def fresh(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Stale", "Fresh"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :stale -> 0
        1 -> 1
        :fresh -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Inner"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Stale"
        :stale -> "Stale"
        1 -> "Fresh"
        :fresh -> "Fresh"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Inner"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Stale" when length(values) == 2 -> List.to_tuple([:stale | values])
      "Stale" -> raise "Enum constructor Stale expects 2 params for Inner"
      "Fresh" when length(values) == 1 -> List.to_tuple([:fresh | values])
      "Fresh" -> raise "Enum constructor Fresh expects 1 params for Inner"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Inner"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:stale | values])
      0 -> raise "Enum constructor Stale expects 2 params for Inner"
      1 when length(values) == 1 -> List.to_tuple([:fresh | values])
      1 -> raise "Enum constructor Fresh expects 1 params for Inner"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Inner"
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
