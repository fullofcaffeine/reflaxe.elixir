defmodule GoldenMessage do
  def external_increment(arg0) do
    {0, arg0}
  end
  def external_reset() do
    {1}
  end
  def __haxe_enum_constructs__() do
    ["ExternalIncrement", "ExternalReset"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :external_increment -> 0
        1 -> 1
        :external_reset -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for GoldenMessage"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "ExternalIncrement"
        :external_increment -> "ExternalIncrement"
        1 -> "ExternalReset"
        :external_reset -> "ExternalReset"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for GoldenMessage"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "ExternalIncrement" when length(values) == 1 -> List.to_tuple([:external_increment | values])
      "ExternalIncrement" -> raise "Enum constructor ExternalIncrement expects 1 params for GoldenMessage"
      "ExternalReset" when values == [] -> List.to_tuple([:external_reset | values])
      "ExternalReset" -> raise "Enum constructor ExternalReset expects 0 params for GoldenMessage"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for GoldenMessage"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:external_increment | values])
      0 -> raise "Enum constructor ExternalIncrement expects 1 params for GoldenMessage"
      1 when values == [] -> List.to_tuple([:external_reset | values])
      1 -> raise "Enum constructor ExternalReset expects 0 params for GoldenMessage"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for GoldenMessage"
    end
  end
  def __haxe_enum_all__() do
    [{:external_reset}]
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
