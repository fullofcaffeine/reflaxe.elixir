defmodule Phoenix.RouteHelper do
  def named(arg0) do
    {:named, arg0}
  end
  def path(arg0) do
    {:path, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Named", "Path"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :named -> 0
        1 -> 1
        :path -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.RouteHelper"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Named"
        :named -> "Named"
        1 -> "Path"
        :path -> "Path"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.RouteHelper"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Named" when length(values) == 1 -> List.to_tuple([:named | values])
      "Named" -> raise "Enum constructor Named expects 1 params for Phoenix.RouteHelper"
      "Path" when length(values) == 1 -> List.to_tuple([:path | values])
      "Path" -> raise "Enum constructor Path expects 1 params for Phoenix.RouteHelper"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.RouteHelper"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:named | values])
      0 -> raise "Enum constructor Named expects 1 params for Phoenix.RouteHelper"
      1 when length(values) == 1 -> List.to_tuple([:path | values])
      1 -> raise "Enum constructor Path expects 1 params for Phoenix.RouteHelper"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.RouteHelper"
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
