defmodule Outcome do
  def ok(arg0) do
    {0, arg0}
  end
  def err(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "Err"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :ok -> 0
        1 -> 1
        :err -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Outcome"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Ok"
        :ok -> "Ok"
        1 -> "Err"
        :err -> "Err"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Outcome"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Ok" when length(values) == 1 -> List.to_tuple([:ok | values])
      "Ok" -> raise "Enum constructor Ok expects 1 params for Outcome"
      "Err" when length(values) == 1 -> List.to_tuple([:err | values])
      "Err" -> raise "Enum constructor Err expects 1 params for Outcome"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Outcome"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:ok | values])
      0 -> raise "Enum constructor Ok expects 1 params for Outcome"
      1 when length(values) == 1 -> List.to_tuple([:err | values])
      1 -> raise "Enum constructor Err expects 1 params for Outcome"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Outcome"
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
