defmodule SoftHookEvent do
  def soft_ping() do
    {0}
  end
  def __haxe_enum_constructs__() do
    ["SoftPing"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :soft_ping -> 0
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for SoftHookEvent"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "SoftPing"
        :soft_ping -> "SoftPing"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for SoftHookEvent"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "SoftPing" when values == [] -> List.to_tuple([:soft_ping | values])
      "SoftPing" -> raise "Enum constructor SoftPing expects 0 params for SoftHookEvent"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for SoftHookEvent"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:soft_ping | values])
      0 -> raise "Enum constructor SoftPing expects 0 params for SoftHookEvent"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for SoftHookEvent"
    end
  end
  def __haxe_enum_all__() do
    [{:soft_ping}]
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
