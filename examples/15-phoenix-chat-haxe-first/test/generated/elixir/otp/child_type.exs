defmodule Elixir.Otp.ChildType do
  def worker() do
    {:worker}
  end
  def supervisor() do
    {:supervisor}
  end
  def __haxe_enum_constructs__() do
    ["Worker", "Supervisor"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :worker -> 0
        1 -> 1
        :supervisor -> 1
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ChildType"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Worker"
        :worker -> "Worker"
        1 -> "Supervisor"
        :supervisor -> "Supervisor"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Otp.ChildType"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Worker" when values == [] -> List.to_tuple([:worker | values])
      "Worker" -> raise "Enum constructor Worker expects 0 params for Elixir.Otp.ChildType"
      "Supervisor" when values == [] -> List.to_tuple([:supervisor | values])
      "Supervisor" -> raise "Enum constructor Supervisor expects 0 params for Elixir.Otp.ChildType"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Otp.ChildType"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:worker | values])
      0 -> raise "Enum constructor Worker expects 0 params for Elixir.Otp.ChildType"
      1 when values == [] -> List.to_tuple([:supervisor | values])
      1 -> raise "Enum constructor Supervisor expects 0 params for Elixir.Otp.ChildType"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Otp.ChildType"
    end
  end
  def __haxe_enum_all__() do
    [{:worker}, {:supervisor}]
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
