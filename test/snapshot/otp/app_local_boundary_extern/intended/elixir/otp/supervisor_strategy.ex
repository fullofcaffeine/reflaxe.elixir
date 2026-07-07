defmodule Elixir.Otp.SupervisorStrategy do
  def one_for_one() do
    {:one_for_one}
  end
  def one_for_all() do
    {:one_for_all}
  end
  def rest_for_one() do
    {:rest_for_one}
  end
  def simple_one_for_one() do
    {:simple_one_for_one}
  end
  def __haxe_enum_constructs__() do
    ["OneForOne", "OneForAll", "RestForOne", "SimpleOneForOne"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :one_for_one -> 0
        1 -> 1
        :one_for_all -> 1
        2 -> 2
        :rest_for_one -> 2
        3 -> 3
        :simple_one_for_one -> 3
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.SupervisorStrategy"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "OneForOne"
        :one_for_one -> "OneForOne"
        1 -> "OneForAll"
        :one_for_all -> "OneForAll"
        2 -> "RestForOne"
        :rest_for_one -> "RestForOne"
        3 -> "SimpleOneForOne"
        :simple_one_for_one -> "SimpleOneForOne"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.SupervisorStrategy"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "OneForOne" when values == [] -> List.to_tuple([:one_for_one | values])
      "OneForOne" -> raise "Enum constructor OneForOne expects 0 params for Elixir.Otp.SupervisorStrategy"
      "OneForAll" when values == [] -> List.to_tuple([:one_for_all | values])
      "OneForAll" -> raise "Enum constructor OneForAll expects 0 params for Elixir.Otp.SupervisorStrategy"
      "RestForOne" when values == [] -> List.to_tuple([:rest_for_one | values])
      "RestForOne" -> raise "Enum constructor RestForOne expects 0 params for Elixir.Otp.SupervisorStrategy"
      "SimpleOneForOne" when values == [] -> List.to_tuple([:simple_one_for_one | values])
      "SimpleOneForOne" -> raise "Enum constructor SimpleOneForOne expects 0 params for Elixir.Otp.SupervisorStrategy"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Otp.SupervisorStrategy"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:one_for_one | values])
      0 -> raise "Enum constructor OneForOne expects 0 params for Elixir.Otp.SupervisorStrategy"
      1 when values == [] -> List.to_tuple([:one_for_all | values])
      1 -> raise "Enum constructor OneForAll expects 0 params for Elixir.Otp.SupervisorStrategy"
      2 when values == [] -> List.to_tuple([:rest_for_one | values])
      2 -> raise "Enum constructor RestForOne expects 0 params for Elixir.Otp.SupervisorStrategy"
      3 when values == [] -> List.to_tuple([:simple_one_for_one | values])
      3 -> raise "Enum constructor SimpleOneForOne expects 0 params for Elixir.Otp.SupervisorStrategy"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Otp.SupervisorStrategy"
    end
  end
  def __haxe_enum_all__() do
    [{:one_for_one}, {:one_for_all}, {:rest_for_one}, {:simple_one_for_one}]
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
