defmodule Elixir.Otp.ShutdownType do
  def brutal() do
    {:brutal}
  end
  def timeout(arg0) do
    {:timeout, arg0}
  end
  def infinity() do
    {:infinity}
  end
  def __haxe_enum_constructs__() do
    ["Brutal", "Timeout", "Infinity"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :brutal -> 0
        1 -> 1
        :timeout -> 1
        2 -> 2
        :infinity -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ShutdownType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Brutal"
        :brutal -> "Brutal"
        1 -> "Timeout"
        :timeout -> "Timeout"
        2 -> "Infinity"
        :infinity -> "Infinity"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ShutdownType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Brutal" when values == [] -> List.to_tuple([:brutal | values])
      "Brutal" -> raise "Enum constructor Brutal expects 0 params for Elixir.Otp.ShutdownType"
      "Timeout" when length(values) == 1 -> List.to_tuple([:timeout | values])
      "Timeout" -> raise "Enum constructor Timeout expects 1 params for Elixir.Otp.ShutdownType"
      "Infinity" when values == [] -> List.to_tuple([:infinity | values])
      "Infinity" -> raise "Enum constructor Infinity expects 0 params for Elixir.Otp.ShutdownType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Otp.ShutdownType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:brutal | values])
      0 -> raise "Enum constructor Brutal expects 0 params for Elixir.Otp.ShutdownType"
      1 when length(values) == 1 -> List.to_tuple([:timeout | values])
      1 -> raise "Enum constructor Timeout expects 1 params for Elixir.Otp.ShutdownType"
      2 when values == [] -> List.to_tuple([:infinity | values])
      2 -> raise "Enum constructor Infinity expects 0 params for Elixir.Otp.ShutdownType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Otp.ShutdownType"
    end
  end
  def __haxe_enum_all__() do
    [{:brutal}, {:infinity}]
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
