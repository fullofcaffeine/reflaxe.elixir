defmodule Elixir.Otp.ApplicationResult do
  def ok(arg0) do
    {:ok, arg0}
  end
  def error(arg0) do
    {:error, arg0}
  end
  def ignore() do
    {:ignore}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "Error", "Ignore"]
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
        :error -> 1
        2 -> 2
        :ignore -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ApplicationResult"
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
        1 -> "Error"
        :error -> "Error"
        2 -> "Ignore"
        :ignore -> "Ignore"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ApplicationResult"
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
      "Ok" -> raise "Enum constructor Ok expects 1 params for Elixir.Otp.ApplicationResult"
      "Error" when length(values) == 1 -> List.to_tuple([:error | values])
      "Error" -> raise "Enum constructor Error expects 1 params for Elixir.Otp.ApplicationResult"
      "Ignore" when values == [] -> List.to_tuple([:ignore | values])
      "Ignore" -> raise "Enum constructor Ignore expects 0 params for Elixir.Otp.ApplicationResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Otp.ApplicationResult"
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
      0 -> raise "Enum constructor Ok expects 1 params for Elixir.Otp.ApplicationResult"
      1 when length(values) == 1 -> List.to_tuple([:error | values])
      1 -> raise "Enum constructor Error expects 1 params for Elixir.Otp.ApplicationResult"
      2 when values == [] -> List.to_tuple([:ignore | values])
      2 -> raise "Enum constructor Ignore expects 0 params for Elixir.Otp.ApplicationResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Otp.ApplicationResult"
    end
  end
  def __haxe_enum_all__() do
    [{:ignore}]
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
