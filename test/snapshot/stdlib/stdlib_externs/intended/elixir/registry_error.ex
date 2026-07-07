defmodule Elixir.RegistryError do
  def already_registered(arg0) do
    {0, arg0}
  end
  def error(arg0) do
    {1, arg0}
  end
  def __haxe_enum_constructs__() do
    ["AlreadyRegistered", "Error"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :already_registered -> 0
        1 -> 1
        :error -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.RegistryError"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "AlreadyRegistered"
        :already_registered -> "AlreadyRegistered"
        1 -> "Error"
        :error -> "Error"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.RegistryError"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "AlreadyRegistered" when length(values) == 1 -> List.to_tuple([:already_registered | values])
      "AlreadyRegistered" -> raise "Enum constructor AlreadyRegistered expects 1 params for Elixir.RegistryError"
      "Error" when length(values) == 1 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 1 params for Elixir.RegistryError"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.RegistryError"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:already_registered | values])
      0 -> raise "Enum constructor AlreadyRegistered expects 1 params for Elixir.RegistryError"
      1 when length(values) == 1 -> List.to_tuple([:error | values])
      1 -> raise "Enum constructor Error expects 1 params for Elixir.RegistryError"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.RegistryError"
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
