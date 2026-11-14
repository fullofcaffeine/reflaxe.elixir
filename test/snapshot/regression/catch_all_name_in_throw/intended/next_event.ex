defmodule NextEvent do
  def now() do
    {0}
  end
  def never() do
    {1}
  end
  def at(arg0) do
    {2, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Now", "Never", "At"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :now -> 0
        1 -> 1
        :never -> 1
        2 -> 2
        :at -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for NextEvent"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Now"
        :now -> "Now"
        1 -> "Never"
        :never -> "Never"
        2 -> "At"
        :at -> "At"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for NextEvent"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Now" when values == [] -> List.to_tuple([:now | values])
      "Now" -> raise "Enum constructor Now expects 0 params for NextEvent"
      "Never" when values == [] -> List.to_tuple([:never | values])
      "Never" -> raise "Enum constructor Never expects 0 params for NextEvent"
      "At" when length(values) == 1 -> List.to_tuple([:at | values])
      "At" -> raise "Enum constructor At expects 1 params for NextEvent"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for NextEvent"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:now | values])
      0 -> raise "Enum constructor Now expects 0 params for NextEvent"
      1 when values == [] -> List.to_tuple([:never | values])
      1 -> raise "Enum constructor Never expects 0 params for NextEvent"
      2 when length(values) == 1 -> List.to_tuple([:at | values])
      2 -> raise "Enum constructor At expects 1 params for NextEvent"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for NextEvent"
    end
  end
  def __haxe_enum_all__() do
    [{:now}, {:never}]
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
