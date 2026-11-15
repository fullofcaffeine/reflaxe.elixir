defmodule SRes do
  def s_ok(arg0) do
    {0, arg0}
  end
  def s_err(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["SOk", "SErr"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :s_ok -> 0
        1 -> 1
        :s_err -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for SRes"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "SOk"
        :s_ok -> "SOk"
        1 -> "SErr"
        :s_err -> "SErr"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for SRes"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "SOk" when length(values) == 1 -> List.to_tuple([:s_ok | values])
      "SOk" -> raise "Enum constructor SOk expects 1 params for SRes"
      "SErr" when length(values) == 1 -> List.to_tuple([:s_err | values])
      "SErr" -> raise "Enum constructor SErr expects 1 params for SRes"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for SRes"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:s_ok | values])
      0 -> raise "Enum constructor SOk expects 1 params for SRes"
      1 when length(values) == 1 -> List.to_tuple([:s_err | values])
      1 -> raise "Enum constructor SErr expects 1 params for SRes"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for SRes"
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
