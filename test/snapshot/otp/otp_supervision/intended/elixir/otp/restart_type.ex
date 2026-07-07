defmodule Elixir.Otp.RestartType do
  def permanent() do
    {:permanent}
  end
  def temporary() do
    {:temporary}
  end
  def transient() do
    {:transient}
  end
  def __haxe_enum_constructs__() do
    ["Permanent", "Temporary", "Transient"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :permanent -> 0
        1 -> 1
        :temporary -> 1
        2 -> 2
        :transient -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.RestartType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Permanent"
        :permanent -> "Permanent"
        1 -> "Temporary"
        :temporary -> "Temporary"
        2 -> "Transient"
        :transient -> "Transient"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.RestartType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Permanent" when values == [] -> List.to_tuple([:permanent | values])
      "Permanent" -> raise "Enum constructor Permanent expects 0 params for Elixir.Otp.RestartType"
      "Temporary" when values == [] -> List.to_tuple([:temporary | values])
      "Temporary" -> raise "Enum constructor Temporary expects 0 params for Elixir.Otp.RestartType"
      "Transient" when values == [] -> List.to_tuple([:transient | values])
      "Transient" -> raise "Enum constructor Transient expects 0 params for Elixir.Otp.RestartType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Otp.RestartType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:permanent | values])
      0 -> raise "Enum constructor Permanent expects 0 params for Elixir.Otp.RestartType"
      1 when values == [] -> List.to_tuple([:temporary | values])
      1 -> raise "Enum constructor Temporary expects 0 params for Elixir.Otp.RestartType"
      2 when values == [] -> List.to_tuple([:transient | values])
      2 -> raise "Enum constructor Transient expects 0 params for Elixir.Otp.RestartType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Otp.RestartType"
    end
  end
  def __haxe_enum_all__() do
    [{:permanent}, {:temporary}, {:transient}]
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
