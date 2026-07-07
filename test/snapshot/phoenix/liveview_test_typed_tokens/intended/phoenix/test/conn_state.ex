defmodule Phoenix.Test.ConnState do
  def unset() do
    {:unset}
  end
  def sent() do
    {:sent}
  end
  def halted() do
    {:halted}
  end
  def __haxe_enum_constructs__() do
    ["Unset", "Sent", "Halted"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :unset -> 0
        1 -> 1
        :sent -> 1
        2 -> 2
        :halted -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Test.ConnState"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Unset"
        :unset -> "Unset"
        1 -> "Sent"
        :sent -> "Sent"
        2 -> "Halted"
        :halted -> "Halted"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.Test.ConnState"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Unset" when values == [] -> List.to_tuple([:unset | values])
      "Unset" -> raise "Enum constructor Unset expects 0 params for Phoenix.Test.ConnState"
      "Sent" when values == [] -> List.to_tuple([:sent | values])
      "Sent" -> raise "Enum constructor Sent expects 0 params for Phoenix.Test.ConnState"
      "Halted" when values == [] -> List.to_tuple([:halted | values])
      "Halted" -> raise "Enum constructor Halted expects 0 params for Phoenix.Test.ConnState"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.Test.ConnState"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:unset | values])
      0 -> raise "Enum constructor Unset expects 0 params for Phoenix.Test.ConnState"
      1 when values == [] -> List.to_tuple([:sent | values])
      1 -> raise "Enum constructor Sent expects 0 params for Phoenix.Test.ConnState"
      2 when values == [] -> List.to_tuple([:halted | values])
      2 -> raise "Enum constructor Halted expects 0 params for Phoenix.Test.ConnState"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.Test.ConnState"
    end
  end
  def __haxe_enum_all__() do
    [{:unset}, {:sent}, {:halted}]
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
